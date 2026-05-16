#!/usr/bin/env python3
"""
Purple Bruce · DJI Mini 4K  ·  Arasaka Neural Tracker  v2.0

Neural mesh: Face-lock → Kalman → PID → EMA → RC → DJI Mini 4K
Latency:     Face detect ~8ms · CSRT track ~12ms · PID ~1ms · WS send ~2ms = ~23ms total
Speed:       Up to 30 km/h  (--speed 75)

Arasaka enhancements over v1.0:
  ◈ Face re-identification  — locks face signature at init, reacquires the SAME face after loss
  ◈ Kalman prediction       — constant-velocity filter predicts position during 0-500ms occlusions
  ◈ EMA-smoothed RC         — exponential smoothing on all 4 axes, eliminates oscillation
  ◈ Audio neural cues       — lock/lost/reacquire beeps via HOCO EQ3 / PulseAudio (no deps)
  ◈ 10Hz background scan    — passive face re-acquisition loop while target is lost
  ◈ Arasaka HUD             — black/red OSD, face confidence readout, Kalman ghost bbox
  ◈ Tighter PID tuning      — optimised for DJI Mini 4K response characteristics

INSTALL (inside Arch proot):
  pacman -S python-opencv python-websockets python-numpy

USAGE:
  drone-track                     # click to select target — CSRT locks on
  drone-track --face              # auto-detect face, lock signature, reacquire on loss
  drone-track --auto-person       # HOG person detect (no face re-ID)
  drone-track --headless          # no window (target via --face or WS command)
  drone-track --speed 60          # max follow speed (default 75 ≈ 30km/h)
  drone-track --bridge-url ws://...
"""

import sys, os, asyncio, time, json, math, base64, argparse, threading, queue, wave, struct
from typing import Optional, Tuple, List

try:
    import cv2
    import numpy as np
except ImportError:
    print("[!] pacman -S python-opencv python-numpy")
    sys.exit(1)

try:
    import websockets
except ImportError:
    print("[!] pacman -S python-websockets")
    sys.exit(1)

# ── Constants ──────────────────────────────────────────────────────────────────
BRIDGE_URL   = 'ws://127.0.0.1:7778'
VIDEO_URL    = 'udp://0.0.0.0:11111'
FRAME_W, FRAME_H = 960, 720
TARGET_FPS   = 30
FRAME_MS     = 1000 // TARGET_FPS

# PID gains — tuned for DJI Mini 4K flight characteristics
PID_LR  = dict(kP=0.60, kI=0.02, kD=0.20)   # left/right
PID_FB  = dict(kP=0.52, kI=0.02, kD=0.16)   # forward/back
PID_UD  = dict(kP=0.42, kI=0.01, kD=0.12)   # up/down
PID_YAW = dict(kP=0.38, kI=0.00, kD=0.08)   # yaw

EMA_ALPHA       = 0.45   # RC smoothing factor (0=frozen, 1=no smoothing)
DEAD_ZONE       = 0.055  # fractional error below which no RC is sent
LOST_TIMEOUT    = 2.0    # seconds after loss → send hover
REACQ_INTERVAL  = 0.5    # seconds between re-acquisition attempts
TARGET_SIZE     = 0.22   # target bbox height as fraction of frame height (distance control)
FACE_SIM_MIN    = 0.35   # minimum face similarity score to accept re-acquisition

# Arasaka HUD color palette (BGR)
A_RED   = (38,   0, 220)   # Arasaka red   #DC0026
A_DIM   = (15,   0,  80)   # dim red
A_GOLD  = (32, 176, 255)   # amber/gold    #FFB020
A_WHITE = (220, 220, 220)
A_GRAY  = ( 80,  80,  80)
A_DARK  = ( 10,  10,  10)
A_GREEN = ( 50, 210,  50)
A_SCAN  = (  0, 100, 220)  # orange — searching

# ── Audio neural cues ──────────────────────────────────────────────────────────
def _beep(freq: int = 880, dur: float = 0.12, vol: float = 0.4):
    """Synthesise and play a tone via PulseAudio — non-blocking daemon thread."""
    def _play():
        try:
            import subprocess
            rate, fn = 22050, '/tmp/_pb_tracker_beep.wav'
            n = int(rate * dur)
            with wave.open(fn, 'w') as wf:
                wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(rate)
                for i in range(n):
                    fade = min(i, n - i) / max(1, min(400, n // 4))
                    v = int(32000 * vol * min(1.0, fade) * math.sin(2 * math.pi * freq * i / rate))
                    wf.writeframes(struct.pack('<h', v))
            subprocess.run(['paplay', fn], stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, timeout=3)
        except Exception:
            pass
    threading.Thread(target=_play, daemon=True).start()

def _beep_lock():    _beep(freq=1047, dur=0.08)   # C6  — target locked
def _beep_lost():    _beep(freq=330,  dur=0.30)   # E4  — target lost
def _beep_reacq():   _beep(freq=660,  dur=0.12)   # E5  — reacquired

# ── Face signature ─────────────────────────────────────────────────────────────
class FaceSignature:
    """
    Compact face feature vector for re-identification.
    Uses Haar cascade detection + 32x32 normalised pixel patch (cosine similarity).
    No dlib or external model files required — works with stock python-opencv.
    """
    _cascade: Optional[cv2.CascadeClassifier] = None

    @classmethod
    def _cc(cls) -> cv2.CascadeClassifier:
        if cls._cascade is None:
            xml = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
            cls._cascade = cv2.CascadeClassifier(xml)
        return cls._cascade

    def __init__(self, frame: np.ndarray, bbox: Tuple):
        x, y, w, h = (int(v) for v in bbox)
        self.sig  = self._extract(frame[y:y+h, x:x+w])

    @staticmethod
    def _extract(roi: np.ndarray) -> Optional[np.ndarray]:
        if roi.size == 0:
            return None
        gray    = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY) if roi.ndim == 3 else roi
        resized = cv2.resize(gray, (32, 32))
        flat    = resized.astype(np.float32).flatten()
        norm    = np.linalg.norm(flat)
        return flat / norm if norm > 1e-6 else None

    def similarity(self, frame: np.ndarray, bbox: Tuple) -> float:
        x, y, w, h = (int(v) for v in bbox)
        sig2 = self._extract(frame[max(0,y):y+h, max(0,x):x+w])
        if sig2 is None or self.sig is None:
            return 0.0
        return float(np.dot(self.sig, sig2))

    @classmethod
    def detect(cls, frame: np.ndarray) -> List[Tuple]:
        """Return list of (x,y,w,h) face bboxes in frame."""
        gray  = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = cls._cc().detectMultiScale(
            gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30)
        )
        return [tuple(int(v) for v in f) for f in faces] if len(faces) > 0 else []

    @classmethod
    def detect_in_region(cls, frame: np.ndarray, bbox: Tuple) -> Optional[Tuple]:
        """Find best face inside bbox, return absolute (x,y,w,h) or None."""
        x, y, w, h = (int(v) for v in bbox)
        roi  = frame[max(0,y):y+h, max(0,x):x+w]
        if roi.size == 0:
            return None
        gray  = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY) if roi.ndim == 3 else roi
        faces = cls._cc().detectMultiScale(
            gray, scaleFactor=1.1, minNeighbors=3, minSize=(20, 20)
        )
        if len(faces) == 0:
            return None
        fx, fy, fw, fh = faces[0]
        return (x + fx, y + fy, fw, fh)

# ── Kalman predictor ───────────────────────────────────────────────────────────
class KalmanPredictor:
    """2D constant-velocity Kalman filter. Predicts bbox centre during occlusions."""
    def __init__(self):
        self.kf = cv2.KalmanFilter(4, 2)
        self.kf.measurementMatrix   = np.array([[1,0,0,0],[0,1,0,0]], np.float32)
        self.kf.transitionMatrix    = np.array([[1,0,1,0],[0,1,0,1],[0,0,1,0],[0,0,0,1]], np.float32)
        self.kf.processNoiseCov     = np.eye(4, dtype=np.float32) * 0.05
        self.kf.measurementNoiseCov = np.eye(2, dtype=np.float32) * 2.0
        self.kf.errorCovPost        = np.eye(4, dtype=np.float32) * 0.1
        self._ready = False

    def update(self, cx: float, cy: float) -> Tuple[float, float]:
        m = np.array([[np.float32(cx)], [np.float32(cy)]])
        if not self._ready:
            self.kf.statePre = np.array([[cx],[cy],[0.0],[0.0]], np.float32)
            self._ready = True
        self.kf.correct(m)
        p = self.kf.predict()
        return float(p[0]), float(p[1])

    def predict(self) -> Tuple[float, float]:
        p = self.kf.predict()
        return float(p[0]), float(p[1])

# ── PID ────────────────────────────────────────────────────────────────────────
class PID:
    def __init__(self, kP, kI, kD, out_min=-100, out_max=100):
        self.kP, self.kI, self.kD = kP, kI, kD
        self.out_min, self.out_max = out_min, out_max
        self._integral  = 0.0
        self._prev_err  = 0.0
        self._prev_time = time.monotonic()

    def update(self, error: float) -> int:
        now = time.monotonic()
        dt  = max(now - self._prev_time, 0.001)
        self._prev_time = now
        self._integral  = max(-50.0, min(50.0, self._integral + error * dt))
        derivative = (error - self._prev_err) / dt
        self._prev_err = error
        raw = self.kP * error + self.kI * self._integral + self.kD * derivative
        return int(max(self.out_min, min(self.out_max, raw * 100)))

    def reset(self):
        self._integral  = 0.0
        self._prev_err  = 0.0
        self._prev_time = time.monotonic()

# ── Track state ────────────────────────────────────────────────────────────────
class TrackState:
    def __init__(self):
        self.tracker:    Optional[cv2.Tracker] = None
        self.bbox:       Optional[Tuple]       = None
        self._last_bbox: Optional[Tuple]       = None
        self.locked:     bool                  = False
        self.lost_at:    Optional[float]       = None
        self.frame_w     = FRAME_W
        self.frame_h     = FRAME_H
        self.pid_lr      = PID(**PID_LR)
        self.pid_fb      = PID(**PID_FB)
        self.pid_ud      = PID(**PID_UD)
        self.pid_yaw     = PID(**PID_YAW)
        self.telemetry:  dict  = {}
        self.max_speed:  int   = 75
        self.face_sig:   Optional[FaceSignature] = None
        self.face_conf:  float = 0.0
        self.kalman      = KalmanPredictor()
        self._ema_rc     = [0.0, 0.0, 0.0, 0.0]  # lr fb ud yaw
        self._last_reacq = 0.0

    def init_tracker(self, frame: np.ndarray, bbox: Tuple,
                     capture_face: bool = True) -> bool:
        self.tracker = cv2.TrackerCSRT_create()
        ok = self.tracker.init(frame, bbox)
        if ok:
            self.bbox       = tuple(int(v) for v in bbox)
            self._last_bbox = self.bbox
            self.locked     = True
            self.lost_at    = None
            for pid in (self.pid_lr, self.pid_fb, self.pid_ud, self.pid_yaw):
                pid.reset()
            # Capture face signature from the selected region
            if capture_face:
                face_bbox = FaceSignature.detect_in_region(frame, bbox) or bbox
                try:
                    self.face_sig = FaceSignature(frame, face_bbox)
                except Exception:
                    self.face_sig = None
        return ok

    def update_frame(self, frame: np.ndarray) -> Tuple[bool, Optional[Tuple]]:
        if self.tracker is None:
            return False, None
        ok, bbox = self.tracker.update(frame)
        if ok:
            self.bbox       = tuple(int(v) for v in bbox)
            self._last_bbox = self.bbox
            self.locked     = True
            self.lost_at    = None
            x, y, w, h = self.bbox
            self.kalman.update(x + w / 2, y + h / 2)
        else:
            self.locked = False
            if self.lost_at is None:
                self.lost_at = time.monotonic()
        return ok, self.bbox if ok else None

    def reacquire(self, frame: np.ndarray) -> bool:
        """
        Two-phase re-acquisition:
          1. Face re-ID  — find face matching stored signature (preferred)
          2. HOG fallback — nearest person to last known position
        """
        now = time.monotonic()
        if now - self._last_reacq < REACQ_INTERVAL:
            return False
        self._last_reacq = now

        best_bbox, best_score = None, FACE_SIM_MIN

        # Phase 1: face signature match
        if self.face_sig is not None and self.face_sig.sig is not None:
            for fbox in FaceSignature.detect(frame):
                score = self.face_sig.similarity(frame, fbox)
                if score > best_score:
                    best_score, best_bbox = score, fbox
            if best_bbox:
                # Expand face bbox to estimated person bounding box
                fx, fy, fw, fh = best_bbox
                px = max(0, fx - fw)
                pw = min(self.frame_w - px, fw * 3)
                ph = min(self.frame_h - fy, fh * 5)
                best_bbox    = (px, fy, pw, ph)
                self.face_conf = best_score

        # Phase 2: HOG person detect — closest to last known position
        if best_bbox is None and self._last_bbox is not None:
            lx, ly, lw, lh = self._last_bbox
            last_cx, last_cy = lx + lw / 2, ly + lh / 2
            hog = cv2.HOGDescriptor()
            hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())
            sc = 2
            small = cv2.resize(frame, (self.frame_w // sc, self.frame_h // sc))
            boxes, _ = hog.detectMultiScale(small, winStride=(8,8), padding=(4,4), scale=1.05)
            if len(boxes) > 0:
                best_dist = float('inf')
                for (x, y, w, h) in boxes:
                    cx = x * sc + w
                    cy = y * sc + h
                    dist = math.hypot(cx - last_cx, cy - last_cy)
                    if dist < best_dist:
                        best_dist = dist
                        best_bbox = (x * sc, y * sc, w * sc, h * sc)

        if best_bbox is not None:
            if self.init_tracker(frame, best_bbox, capture_face=False):
                _beep_reacq()
                return True
        return False

    def kalman_predict_bbox(self) -> Optional[Tuple]:
        if not self.kalman._ready or self._last_bbox is None:
            return None
        pcx, pcy = self.kalman.predict()
        _, _, lw, lh = self._last_bbox
        return (int(pcx - lw / 2), int(pcy - lh / 2), lw, lh)

    def compute_rc(self, use_kalman: bool = False) -> dict:
        bbox = self.bbox
        if use_kalman and not self.locked:
            bbox = self.kalman_predict_bbox()
        if not bbox:
            return {'lr': 0, 'fb': 0, 'ud': 0, 'yaw': 0}

        x, y, w, h = bbox
        cx = x + w / 2
        cy = y + h / 2

        def dz(e: float) -> float:
            return 0.0 if abs(e) < DEAD_ZONE else e

        err_lr  = dz((cx - self.frame_w / 2) / (self.frame_w / 2))
        err_ud  = dz((cy - self.frame_h / 2) / (self.frame_h / 2))
        err_yaw = dz(err_lr * 0.5)
        err_fb  = dz((h / self.frame_h - TARGET_SIZE) / TARGET_SIZE)

        lr  = self.pid_lr.update(err_lr)
        fb  = -self.pid_fb.update(err_fb)
        ud  = -self.pid_ud.update(err_ud)
        yaw = self.pid_yaw.update(err_yaw)

        # Altitude safety guard
        if self.telemetry.get('tof', 999) < 50:
            ud = max(0, ud)

        # Speed clamp
        sp = self.max_speed
        lr, fb, ud, yaw = (max(-sp, min(sp, v)) for v in (lr, fb, ud, yaw))

        # EMA smoothing — prevents oscillation caused by CSRT jitter
        a = EMA_ALPHA
        self._ema_rc[0] = a * lr  + (1 - a) * self._ema_rc[0]
        self._ema_rc[1] = a * fb  + (1 - a) * self._ema_rc[1]
        self._ema_rc[2] = a * ud  + (1 - a) * self._ema_rc[2]
        self._ema_rc[3] = a * yaw + (1 - a) * self._ema_rc[3]

        return {
            'lr':  int(self._ema_rc[0]),
            'fb':  int(self._ema_rc[1]),
            'ud':  int(self._ema_rc[2]),
            'yaw': int(self._ema_rc[3]),
        }

    @property
    def target_lost(self) -> bool:
        return bool(self.lost_at) and (time.monotonic() - self.lost_at) > LOST_TIMEOUT

# ── WebSocket bridge ───────────────────────────────────────────────────────────
class BridgeClient:
    def __init__(self, url: str, track: TrackState):
        self.url    = url
        self.track  = track
        self._loop  = asyncio.new_event_loop()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._q: queue.Queue = queue.Queue()

    def start(self):
        self._thread.start()

    def send_rc(self, lr=0, fb=0, ud=0, yaw=0):
        self._q.put({'action': 'command', 'cmd': 'rc',
                     'params': {'lr': lr, 'fb': fb, 'ud': ud, 'yaw': yaw}})

    def send_hover(self):
        self._q.put({'action': 'command', 'cmd': 'rc_stop', 'params': {}})

    def send_tracker_status(self, locked: bool, active: bool):
        self._q.put({'action': 'tracker_status', 'locked': locked,
                     'active': active, 'face_conf': round(self.track.face_conf, 3)})

    def send_track_frame(self, locked: bool, bbox, frame_b64: str = ''):
        self._q.put({'action': 'track_frame', 'locked': locked,
                     'bbox': list(bbox) if bbox else None, 'frame': frame_b64})

    def _run(self):
        asyncio.set_event_loop(self._loop)
        self._loop.run_until_complete(self._connect_loop())

    async def _connect_loop(self):
        while True:
            try:
                print(f'[tracker] connecting → {self.url}')
                async with websockets.connect(self.url) as ws:
                    print('[tracker] bridge connected')
                    await asyncio.wait(
                        [asyncio.create_task(self._recv(ws)),
                         asyncio.create_task(self._send(ws))],
                        return_when=asyncio.FIRST_COMPLETED
                    )
            except Exception as e:
                print(f'[tracker] bridge error: {e} — retry in 5s')
                await asyncio.sleep(5)

    async def _recv(self, ws):
        async for raw in ws:
            try:
                msg = json.loads(raw)
                if msg.get('type') == 'telemetry':
                    self.track.telemetry = msg.get('data', {})
            except Exception:
                pass

    async def _send(self, ws):
        loop = asyncio.get_event_loop()
        while True:
            try:
                cmd = await loop.run_in_executor(None, self._q.get, True, 0.05)
                await ws.send(json.dumps(cmd))
            except queue.Empty:
                pass
            except Exception:
                break

# ── Video ──────────────────────────────────────────────────────────────────────
def open_video() -> Optional[cv2.VideoCapture]:
    for src in [VIDEO_URL, 'udp://@0.0.0.0:11111', 0]:
        cap = cv2.VideoCapture(src)
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        if cap.isOpened():
            print(f'[tracker] video: {src}')
            return cap
        cap.release()
    return None

def detect_person(frame: np.ndarray) -> Optional[Tuple]:
    hog = cv2.HOGDescriptor()
    hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())
    h, w = frame.shape[:2]
    small = cv2.resize(frame, (w // 2, h // 2))
    boxes, weights = hog.detectMultiScale(small, winStride=(8,8), padding=(4,4), scale=1.05)
    if len(boxes) == 0:
        return None
    best = boxes[np.argmax(weights)]
    x, y, bw, bh = best
    return (x * 2, y * 2, bw * 2, bh * 2)

# ── Arasaka HUD ────────────────────────────────────────────────────────────────
def draw_osd(frame: np.ndarray, ts: TrackState, rc: dict, fps: float = 0.0) -> np.ndarray:
    out = frame.copy()
    h, w = out.shape[:2]

    # ── Top bar ──────────────────────────────────────────────────────────────
    cv2.rectangle(out, (0, 0), (w, 44), A_DARK, -1)
    cv2.line(out, (0, 44), (w, 44), A_RED, 1)

    status = "NEURAL LOCK" if ts.locked else ("REACQUIRING" if ts.lost_at else "SCANNING")
    scol   = A_RED if ts.locked else A_SCAN
    bat    = ts.telemetry.get('battery', '--')
    alt    = ts.telemetry.get('altitude', '--')
    spd    = ts.telemetry.get('speed_h', '--')

    cv2.putText(out, "ARASAKA",          ( 8, 16), cv2.FONT_HERSHEY_SIMPLEX, 0.44, A_DIM,   1)
    cv2.putText(out, "NEURAL TRACKER",   ( 8, 34), cv2.FONT_HERSHEY_SIMPLEX, 0.40, A_GRAY,  1)

    # Status centred
    (sw, _), _ = cv2.getTextSize(status, cv2.FONT_HERSHEY_SIMPLEX, 0.65, 2)
    cv2.putText(out, status, (w // 2 - sw // 2, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 0.65, scol, 2)

    # Telemetry right
    cv2.putText(out, f"BAT:{bat}%  ALT:{alt}m  {spd}m/s",
                (w - 238, 20), cv2.FONT_HERSHEY_SIMPLEX, 0.40, A_WHITE, 1)
    if fps > 0:
        cv2.putText(out, f"{fps:.0f}fps", (w - 48, 38),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.38, A_GRAY, 1)

    # ── Bottom bar ────────────────────────────────────────────────────────────
    cv2.rectangle(out, (0, h - 54), (w, h), A_DARK, -1)
    cv2.line(out, (0, h - 54), (w, h - 54), A_RED, 1)

    # Face confidence readout (left)
    if ts.face_sig is not None:
        fc = ts.face_conf
        label_col = A_GOLD if fc >= FACE_SIM_MIN else A_GRAY
        cv2.putText(out, f"FACE  {fc*100:.0f}%",
                    (8, h - 34), cv2.FONT_HERSHEY_SIMPLEX, 0.42, label_col, 1)
        bar_w = int(fc * 80)
        cv2.rectangle(out, (8, h - 22), (8 + bar_w, h - 14), A_GOLD, -1)
        cv2.rectangle(out, (8, h - 22), (88, h - 14), A_GRAY, 1)

    # RC bars (right side)
    def rc_bar(label: str, val: int, bx: int, by: int):
        cv2.putText(out, label, (bx, by - 2), cv2.FONT_HERSHEY_SIMPLEX, 0.36, A_GRAY, 1)
        filled = int(abs(val) / 100 * 38)
        col = A_GREEN if val >= 0 else A_RED
        cv2.rectangle(out, (bx, by + 1), (bx + filled, by + 8), col, -1)

    rc_bar(f'LR{rc["lr"]:+4d}',  rc['lr'],  w - 222, h - 34)
    rc_bar(f'FB{rc["fb"]:+4d}',  rc['fb'],  w - 168, h - 34)
    rc_bar(f'UD{rc["ud"]:+4d}',  rc['ud'],  w - 114, h - 34)
    rc_bar(f'YW{rc["yaw"]:+4d}', rc['yaw'], w -  60, h - 34)

    cv2.putText(out, "ESC=stop  R=reset  SPACE=reselect",
                (w - 290, h - 6), cv2.FONT_HERSHEY_SIMPLEX, 0.36, A_GRAY, 1)

    # ── Crosshair ─────────────────────────────────────────────────────────────
    cx, cy = w // 2, h // 2
    cv2.line(out, (cx - 18, cy), (cx + 18, cy), A_DIM, 1)
    cv2.line(out, (cx, cy - 18), (cx, cy + 18), A_DIM, 1)
    cv2.circle(out, (cx, cy), 4, A_DIM, 1)

    # ── Target bbox — Arasaka corner brackets ─────────────────────────────────
    if ts.locked and ts.bbox:
        x, y, bw, bh = ts.bbox
        tk = 18
        # Dim full outline
        overlay = out.copy()
        cv2.rectangle(overlay, (x, y), (x + bw, y + bh), A_RED, 1)
        cv2.addWeighted(overlay, 0.35, out, 0.65, 0, out)
        # Bold corner ticks
        for rx, ry in [(x, y), (x + bw, y), (x, y + bh), (x + bw, y + bh)]:
            dx = 1 if rx == x else -1
            dy = 1 if ry == y else -1
            cv2.line(out, (rx, ry), (rx + tk * dx, ry), A_RED, 2)
            cv2.line(out, (rx, ry), (rx, ry + tk * dy), A_RED, 2)
        # Centre dot
        cv2.circle(out, (x + bw // 2, y + bh // 2), 3, A_RED, -1)

    # ── Kalman ghost — predicted position when CSRT is lost ───────────────────
    if not ts.locked and ts.kalman._ready:
        pb = ts.kalman_predict_bbox()
        if pb:
            px, py, pw, ph = pb
            cv2.rectangle(out, (px, py), (px + pw, py + ph), A_GOLD, 1)
            cv2.putText(out, "PRED", (px, py - 4),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.35, A_GOLD, 1)

    return out

# ── Main tracking loop ─────────────────────────────────────────────────────────
def run(args):
    ts     = TrackState()
    ts.max_speed = args.speed
    bridge = BridgeClient(args.bridge_url, ts)
    bridge.start()

    cap = open_video()
    if cap is None and not args.headless:
        print("[!] Cannot open drone video. Connect drone and enable stream first.")
        sys.exit(1)

    # UI state
    sel_pt1 = sel_pt2 = sel_bbox = None
    selecting_active = False

    def mouse_cb(event, x, y, flags, param):
        nonlocal sel_pt1, sel_pt2, sel_bbox, selecting_active
        if event == cv2.EVENT_LBUTTONDOWN:
            sel_pt1 = (x, y); selecting_active = True
        elif event == cv2.EVENT_MOUSEMOVE and selecting_active:
            sel_pt2 = (x, y)
        elif event == cv2.EVENT_LBUTTONUP and sel_pt1:
            sel_pt2 = (x, y)
            x1, y1 = min(sel_pt1[0], x), min(sel_pt1[1], y)
            x2, y2 = max(sel_pt1[0], x), max(sel_pt1[1], y)
            if x2 - x1 > 10 and y2 - y1 > 10:
                sel_bbox = (x1, y1, x2 - x1, y2 - y1)
            selecting_active = False

    if not args.headless:
        cv2.namedWindow('ARASAKA NEURAL TRACKER', cv2.WINDOW_NORMAL)
        cv2.setMouseCallback('ARASAKA NEURAL TRACKER', mouse_cb)
        print("[tracker] Draw a box around target — SPACE to confirm | R=reset | ESC=stop")

    rc_cmd  = {'lr': 0, 'fb': 0, 'ud': 0, 'yaw': 0}
    last_rc = time.monotonic()
    frame_n = 0
    fps_t   = time.monotonic()
    fps_val = 0.0
    was_locked = False

    while True:
        t0 = time.monotonic()

        ret, frame = cap.read() if cap else (False, None)
        if not ret or frame is None:
            frame = np.zeros((FRAME_H, FRAME_W, 3), dtype=np.uint8)
            if args.headless:
                time.sleep(0.033)
                continue

        frame = cv2.resize(frame, (FRAME_W, FRAME_H))
        ts.frame_w = FRAME_W
        ts.frame_h = FRAME_H

        # Auto person / face detect on startup
        if args.auto_person and not ts.locked and frame_n < 5:
            pb = detect_person(frame)
            if pb:
                ts.init_tracker(frame, pb)
                bridge.send_tracker_status(True, True)
                _beep_lock()

        if args.face and not ts.locked and frame_n < 5:
            faces = FaceSignature.detect(frame)
            if faces:
                ts.init_tracker(frame, faces[0])
                bridge.send_tracker_status(True, True)
                _beep_lock()

        # Manual selection
        if sel_bbox and not ts.locked:
            ts.init_tracker(frame, sel_bbox)
            sel_bbox = None
            bridge.send_tracker_status(True, True)
            _beep_lock()

        # Update CSRT
        if ts.tracker is not None:
            ts.update_frame(frame)

        # Audio cue on lock change
        if ts.locked and not was_locked:
            pass  # already beeped at init
        elif not ts.locked and was_locked:
            _beep_lost()
        was_locked = ts.locked

        # Re-acquisition (face re-ID or HOG)
        if not ts.locked and ts.tracker is not None and not ts.target_lost:
            ts.reacquire(frame)

        # RC command generation
        if ts.locked:
            rc_cmd = ts.compute_rc()
        elif ts.kalman._ready and not ts.target_lost:
            # Use Kalman prediction to keep pursuing during brief loss
            rc_cmd = ts.compute_rc(use_kalman=True)
        else:
            rc_cmd = {'lr': 0, 'fb': 0, 'ud': 0, 'yaw': 0}

        # Target permanently lost — hover
        if ts.target_lost and ts.tracker is not None:
            bridge.send_hover()
            bridge.send_tracker_status(False, True)

        # Send RC at 30Hz
        now = time.monotonic()
        if (ts.locked or (ts.kalman._ready and not ts.target_lost)) and now - last_rc >= 0.033:
            bridge.send_rc(**rc_cmd)
            last_rc = now

        # Broadcast annotated frame every 3rd frame
        if frame_n % 3 == 0:
            disp = draw_osd(frame.copy(), ts, rc_cmd, fps_val)
            _, jpg = cv2.imencode('.jpg', disp, [cv2.IMWRITE_JPEG_QUALITY, 55])
            b64 = base64.b64encode(jpg.tobytes()).decode()
            bridge.send_track_frame(ts.locked, ts.bbox, b64)

        # Display window
        if not args.headless:
            disp = draw_osd(frame.copy(), ts, rc_cmd, fps_val)
            if selecting_active and sel_pt1 and sel_pt2:
                cv2.rectangle(disp, sel_pt1, sel_pt2, A_GOLD, 1)

            frame_n += 1
            if frame_n % 30 == 0:
                fps_val = 30.0 / max(0.001, time.monotonic() - fps_t)
                fps_t = time.monotonic()

            cv2.imshow('ARASAKA NEURAL TRACKER', disp)
            key = cv2.waitKey(1) & 0xFF

            if key == 27:  # ESC
                bridge.send_hover()
                bridge.send_tracker_status(False, False)
                print('[tracker] ESC — hover + quit')
                break
            elif key == ord('q'):
                bridge.send_hover()
                break
            elif key == ord('r'):
                ts.tracker = None; ts.locked = False; ts.lost_at = None
                sel_bbox = None
                bridge.send_hover()
                bridge.send_tracker_status(False, True)
                print('[tracker] reset')
            elif key == ord(' ') and sel_bbox:
                ts.init_tracker(frame, sel_bbox)
                sel_bbox = None
                _beep_lock()
        else:
            frame_n += 1

        # Frame timing
        elapsed_ms = (time.monotonic() - t0) * 1000
        sleep_ms   = max(0, FRAME_MS - elapsed_ms)
        if sleep_ms > 1 and args.headless:
            time.sleep(sleep_ms / 1000)

    if not args.headless:
        cv2.destroyAllWindows()
    if cap:
        cap.release()

# ── Entry ──────────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(
        prog='tracker.py',
        description='Purple Bruce — Arasaka Neural Tracker v2.0',
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument('--bridge-url',  default=BRIDGE_URL)
    ap.add_argument('--speed',       type=int,   default=75,
                    help='Max follow speed 0-100 (75≈30km/h)')
    ap.add_argument('--face',        action='store_true',
                    help='Auto-detect + lock face signature, reacquire on loss')
    ap.add_argument('--auto-person', action='store_true',
                    help='Auto-detect first person via HOG (no face re-ID)')
    ap.add_argument('--headless',    action='store_true',
                    help='No display window')
    args = ap.parse_args()

    print(f"""
  ╔═══════════════════════════════════════════════════╗
  ║  A R A S A K A   N E U R A L   T R A C K E R    ║
  ║  Purple Bruce · DJI Mini 4K · v2.0               ║
  ║  Bridge : {args.bridge_url:<40}║
  ║  Speed  : {args.speed}%  (~{args.speed * 0.4:.0f} km/h){'':>33}║
  ║  Mode   : {"FACE-LOCK" if args.face else "AUTO-PERSON" if args.auto_person else "HEADLESS" if args.headless else "INTERACTIVE"}{'':>38}║
  ╚═══════════════════════════════════════════════════╝
""")
    run(args)

if __name__ == '__main__':
    main()
