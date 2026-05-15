#!/usr/bin/env python3
"""
Purple Bruce — DJI Mini 4K Autonomous Target Tracker  v1.0
Follow-Me / target tracking at 20-30ms response, up to 30 km/h.

HOW IT WORKS:
  1. Connects to the mini4k.py bridge (ws://127.0.0.1:7778)
  2. Opens drone video stream (UDP port 11111, H264)
  3. User selects target: click in preview window OR auto-detect first person
  4. OpenCV CSRT tracker locks on target each frame (~10ms)
  5. PID controllers convert tracking error → rc velocity commands
  6. Drone follows target at up to 30 km/h

INSTALL (inside Arch proot):
  pacman -S python-opencv python-websockets python-numpy

USAGE:
  python3 tracker.py                    # interactive — click to select target
  python3 tracker.py --auto-person      # auto-detect first person using HOG
  python3 tracker.py --headless         # no display (target set via WS command)
  python3 tracker.py --speed 75         # max follow speed (0-100, 75≈30km/h)
  python3 tracker.py --bridge-url ws://127.0.0.1:7778

TARGET SELECTION (interactive mode):
  - Window shows drone video
  - Draw a box around the target with mouse (click + drag)
  - Press SPACE to confirm selection → tracking starts
  - Press R to reset (re-select target)
  - Press Q or ESC to quit

SAFETY:
  - Press ESC at any time → rc 0 0 0 0 (hover)
  - Tracker sends rc_stop if target lost for >2 seconds
  - Min altitude guard: if tof < 50cm, disables downward commands
"""

import sys, os, asyncio, time, json, math, base64, argparse, threading, queue
from typing import Optional, Tuple

# ── Deps check ────────────────────────────────────────────────────────────────
try:
    import cv2
    import numpy as np
except ImportError:
    print("[!] Install OpenCV: pacman -S python-opencv python-numpy")
    sys.exit(1)

try:
    import websockets
except ImportError:
    print("[!] Install websockets: pacman -S python-websockets")
    sys.exit(1)

# ── Constants ─────────────────────────────────────────────────────────────────
BRIDGE_URL   = 'ws://127.0.0.1:7778'
VIDEO_URL    = 'udp://0.0.0.0:11111'   # H264 from drone
FRAME_W      = 960
FRAME_H      = 720
TARGET_FPS   = 30
FRAME_MS     = 1000 // TARGET_FPS      # ~33ms

# PID gains — tune these for your drone
# kP: proportional (main response), kI: integral (drift correction), kD: derivative (damping)
PID_LR  = dict(kP=0.55, kI=0.02, kD=0.18)   # left/right
PID_FB  = dict(kP=0.50, kI=0.02, kD=0.15)   # forward/back
PID_UD  = dict(kP=0.40, kI=0.01, kD=0.10)   # up/down (distance control)
PID_YAW = dict(kP=0.35, kI=0.00, kD=0.08)   # yaw (face target)

DEAD_ZONE      = 0.06   # fractional offset from center — below this, no command
LOST_TIMEOUT   = 2.0    # seconds before declaring target lost → hover
TARGET_SIZE    = 0.22   # target bbox height as fraction of frame — maintain this distance

# Color palette (BGR for OpenCV)
COL_LOCK   = (0,  255, 50)    # green — locked
COL_SEARCH = (0, 165, 255)    # orange — searching
COL_BOX    = (135, 92, 246)   # purple — bbox
COL_TEXT   = (255, 255, 255)  # white
COL_BAR    = (50, 50, 50)     # dark bg bar

# ── PID Controller ────────────────────────────────────────────────────────────
class PID:
    def __init__(self, kP: float, kI: float, kD: float, out_min=-100, out_max=100):
        self.kP, self.kI, self.kD = kP, kI, kD
        self.out_min, self.out_max = out_min, out_max
        self._integral  = 0.0
        self._prev_err  = 0.0
        self._prev_time = time.monotonic()

    def update(self, error: float) -> int:
        now  = time.monotonic()
        dt   = max(now - self._prev_time, 0.001)
        self._prev_time = now

        self._integral   += error * dt
        self._integral    = max(-50, min(50, self._integral))  # anti-windup
        derivative        = (error - self._prev_err) / dt
        self._prev_err    = error

        raw = self.kP * error + self.kI * self._integral + self.kD * derivative
        return int(max(self.out_min, min(self.out_max, raw * 100)))

    def reset(self):
        self._integral  = 0.0
        self._prev_err  = 0.0
        self._prev_time = time.monotonic()

# ── Tracker state ─────────────────────────────────────────────────────────────
class TrackState:
    def __init__(self):
        self.tracker: Optional[cv2.Tracker] = None
        self.bbox:    Optional[Tuple]       = None     # (x, y, w, h) pixels
        self.locked:  bool                  = False
        self.lost_at: Optional[float]       = None
        self.frame_w: int                   = FRAME_W
        self.frame_h: int                   = FRAME_H
        self.pid_lr   = PID(**PID_LR)
        self.pid_fb   = PID(**PID_FB)
        self.pid_ud   = PID(**PID_UD)
        self.pid_yaw  = PID(**PID_YAW)
        self.telemetry: dict = {}
        self.max_speed: int  = 75  # 75 ≈ 30 km/h

    def init_tracker(self, frame: np.ndarray, bbox: Tuple) -> bool:
        self.tracker = cv2.TrackerCSRT_create()
        ok = self.tracker.init(frame, bbox)
        if ok:
            self.bbox   = bbox
            self.locked = True
            self.lost_at = None
            self.pid_lr.reset()
            self.pid_fb.reset()
            self.pid_ud.reset()
            self.pid_yaw.reset()
        return ok

    def update(self, frame: np.ndarray) -> Tuple[bool, Optional[Tuple]]:
        if self.tracker is None:
            return False, None
        ok, bbox = self.tracker.update(frame)
        if ok:
            self.bbox    = tuple(int(v) for v in bbox)
            self.locked  = True
            self.lost_at = None
        else:
            self.locked = False
            if self.lost_at is None:
                self.lost_at = time.monotonic()
        return ok, self.bbox if ok else None

    def compute_rc(self) -> dict:
        """Convert current bbox position to rc velocity commands."""
        if not self.locked or self.bbox is None:
            return {'lr': 0, 'fb': 0, 'ud': 0, 'yaw': 0}

        x, y, w, h = self.bbox
        cx = x + w / 2
        cy = y + h / 2

        # Normalized errors (-1.0 to 1.0, 0 = center)
        err_lr  = (cx - self.frame_w / 2) / (self.frame_w / 2)   # +right
        err_ud  = (cy - self.frame_h / 2) / (self.frame_h / 2)   # +down
        err_yaw = err_lr * 0.5  # gentle yaw to face target

        # Distance control: compare bbox height to target fraction
        bbox_frac = h / self.frame_h
        err_fb    = (bbox_frac - TARGET_SIZE) / TARGET_SIZE   # +target too close → back

        # Apply dead zone
        err_lr  = 0.0 if abs(err_lr)  < DEAD_ZONE else err_lr
        err_ud  = 0.0 if abs(err_ud)  < DEAD_ZONE else err_ud
        err_fb  = 0.0 if abs(err_fb)  < DEAD_ZONE else err_fb
        err_yaw = 0.0 if abs(err_yaw) < DEAD_ZONE else err_yaw

        lr  = self.pid_lr.update(err_lr)
        fb  = -self.pid_fb.update(err_fb)   # invert: bbox too big → back
        ud  = -self.pid_ud.update(err_ud)   # invert: target below center → go down
        yaw = self.pid_yaw.update(err_yaw)

        # Altitude safety guard
        if self.telemetry.get('tof', 999) < 50:
            ud = max(0, ud)  # prevent going lower than 50cm

        # Clamp to max_speed
        sp = self.max_speed
        lr  = max(-sp, min(sp, lr))
        fb  = max(-sp, min(sp, fb))
        ud  = max(-sp, min(sp, ud))
        yaw = max(-sp, min(sp, yaw))

        return {'lr': lr, 'fb': fb, 'ud': ud, 'yaw': yaw}

    @property
    def target_lost(self) -> bool:
        if not self.lost_at:
            return False
        return (time.monotonic() - self.lost_at) > LOST_TIMEOUT

# ── WebSocket bridge ──────────────────────────────────────────────────────────
class BridgeClient:
    def __init__(self, url: str, track: TrackState):
        self.url    = url
        self.track  = track
        self.ws     = None
        self._loop  = asyncio.new_event_loop()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._cmd_q: queue.Queue = queue.Queue()

    def start(self):
        self._thread.start()

    def send_rc(self, lr=0, fb=0, ud=0, yaw=0):
        self._cmd_q.put({'action': 'command', 'cmd': 'rc',
                         'params': {'lr': lr, 'fb': fb, 'ud': ud, 'yaw': yaw}})

    def send_hover(self):
        self._cmd_q.put({'action': 'command', 'cmd': 'rc_stop', 'params': {}})

    def send_tracker_status(self, locked: bool, active: bool):
        self._cmd_q.put({'action': 'tracker_status', 'locked': locked, 'active': active})

    def send_track_frame(self, locked: bool, bbox, frame_jpg_b64: str = ''):
        self._cmd_q.put({'action': 'track_frame', 'locked': locked,
                         'bbox': list(bbox) if bbox else None, 'frame': frame_jpg_b64})

    def _run(self):
        asyncio.set_event_loop(self._loop)
        self._loop.run_until_complete(self._connect_loop())

    async def _connect_loop(self):
        while True:
            try:
                print(f'[tracker] connecting to bridge {self.url}...')
                async with websockets.connect(self.url) as ws:
                    self.ws = ws
                    print(f'[tracker] bridge connected')
                    recv_task = asyncio.create_task(self._recv(ws))
                    send_task = asyncio.create_task(self._send(ws))
                    await asyncio.wait([recv_task, send_task],
                                       return_when=asyncio.FIRST_COMPLETED)
            except Exception as e:
                print(f'[tracker] bridge error: {e} — retry in 5s')
                self.ws = None
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
                cmd = await loop.run_in_executor(None, self._cmd_q.get, True, 0.05)
                await ws.send(json.dumps(cmd))
            except queue.Empty:
                pass
            except Exception:
                break

# ── Video capture ─────────────────────────────────────────────────────────────
def open_video() -> Optional[cv2.VideoCapture]:
    sources = [VIDEO_URL, 'udp://@0.0.0.0:11111', 0]
    for src in sources:
        cap = cv2.VideoCapture(src)
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        if cap.isOpened():
            print(f'[tracker] video opened: {src}')
            return cap
        cap.release()
    return None

# ── Auto person detect ────────────────────────────────────────────────────────
def detect_person(frame: np.ndarray) -> Optional[Tuple]:
    hog = cv2.HOGDescriptor()
    hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())
    h_frame, w_frame = frame.shape[:2]
    small = cv2.resize(frame, (w_frame // 2, h_frame // 2))
    boxes, weights = hog.detectMultiScale(
        small, winStride=(8, 8), padding=(4, 4), scale=1.05
    )
    if len(boxes) == 0:
        return None
    # Take highest-confidence detection
    best = boxes[np.argmax(weights)]
    x, y, w, h = best
    return (x * 2, y * 2, w * 2, h * 2)

# ── OSD overlay ──────────────────────────────────────────────────────────────
def draw_osd(frame: np.ndarray, ts: TrackState, rc: dict) -> np.ndarray:
    h, w = frame.shape[:2]
    overlay = frame.copy()

    # Top bar
    cv2.rectangle(overlay, (0, 0), (w, 36), COL_BAR, -1)
    alpha = 0.75
    frame = cv2.addWeighted(overlay, alpha, frame, 1 - alpha, 0)

    status = "LOCKED" if ts.locked else ("LOST" if ts.lost_at else "SEARCHING")
    col    = COL_LOCK if ts.locked else COL_SEARCH
    bat    = ts.telemetry.get('battery', '--')
    alt    = ts.telemetry.get('altitude', '--')
    spd    = ts.telemetry.get('speed_h', '--')

    cv2.putText(frame, f"PURPLE BRUCE TRACKER  |  {status}",
                (8, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.6, col, 2)
    cv2.putText(frame, f"BAT:{bat}%  ALT:{alt}m  SPD:{spd}m/s",
                (w - 280, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.5, COL_TEXT, 1)

    # Crosshair
    cx, cy = w // 2, h // 2
    cv2.line(frame, (cx - 20, cy), (cx + 20, cy), (80, 80, 80), 1)
    cv2.line(frame, (cx, cy - 20), (cx, cy + 20), (80, 80, 80), 1)

    # Bbox
    if ts.locked and ts.bbox:
        x, y, bw, bh = ts.bbox
        cv2.rectangle(frame, (x, y), (x + bw, y + bh), COL_BOX, 2)
        # Corner ticks
        tk = 12
        for rx, ry in [(x, y), (x+bw, y), (x, y+bh), (x+bw, y+bh)]:
            dx = 1 if rx == x else -1
            dy = 1 if ry == y else -1
            cv2.line(frame, (rx, ry), (rx + tk*dx, ry), COL_LOCK, 2)
            cv2.line(frame, (rx, ry), (rx, ry + tk*dy), COL_LOCK, 2)

    # RC vectors at bottom
    bar_y = h - 12
    def draw_bar(label, val, bx):
        cv2.putText(frame, label, (bx, bar_y - 4),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.4, COL_TEXT, 1)
        filled = int(abs(val) / 100 * 30)
        col = (0, 200, 80) if val >= 0 else (80, 80, 255)
        cv2.rectangle(frame, (bx, bar_y), (bx + filled, bar_y + 6), col, -1)

    draw_bar(f'LR:{rc["lr"]:+4d}',  rc['lr'],  8)
    draw_bar(f'FB:{rc["fb"]:+4d}',  rc['fb'],  90)
    draw_bar(f'UD:{rc["ud"]:+4d}',  rc['ud'],  172)
    draw_bar(f'YW:{rc["yaw"]:+4d}', rc['yaw'], 254)

    cv2.putText(frame, "ESC=stop  R=reset  SPACE=reselect",
                (w - 290, h - 6), cv2.FONT_HERSHEY_SIMPLEX, 0.38, (100, 100, 100), 1)
    return frame

# ── Main tracking loop ────────────────────────────────────────────────────────
def run(args):
    ts     = TrackState()
    ts.max_speed = args.speed
    bridge = BridgeClient(args.bridge_url, ts)
    bridge.start()

    cap = open_video()
    if cap is None and not args.headless:
        print("[!] Cannot open drone video. Is drone connected and streamon active?")
        print("    Run in Purple Bruce web UI: Drone panel → Stream ON")
        print("    Or: connect drone then run: nemoclaw '!python3 netrunner/drone/tracker.py'")
        sys.exit(1)

    selecting  = not args.auto_person and not args.headless
    sel_bbox   = None
    sel_pt1    = None
    sel_pt2    = None
    selecting_active = False

    def mouse_cb(event, x, y, flags, param):
        nonlocal sel_pt1, sel_pt2, sel_bbox, selecting_active
        if event == cv2.EVENT_LBUTTONDOWN:
            sel_pt1 = (x, y)
            selecting_active = True
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
        cv2.namedWindow('Purple Bruce Tracker', cv2.WINDOW_NORMAL)
        cv2.setMouseCallback('Purple Bruce Tracker', mouse_cb)
        print("[tracker] Draw a box around your target, then press SPACE")

    rc_cmd   = {'lr': 0, 'fb': 0, 'ud': 0, 'yaw': 0}
    last_rc  = time.monotonic()
    frame_n  = 0
    fps_t    = time.monotonic()
    fps_val  = 0.0

    while True:
        t0 = time.monotonic()

        ret, frame = (cap.read() if cap else (False, None))
        if not ret or frame is None:
            # Generate a black frame so tracking loop keeps running
            frame = np.zeros((FRAME_H, FRAME_W, 3), dtype=np.uint8)
            if args.headless:
                time.sleep(0.033)
                continue

        frame  = cv2.resize(frame, (FRAME_W, FRAME_H))
        ts.frame_w = FRAME_W
        ts.frame_h = FRAME_H

        # ── Auto person detect (first frame only) ──────────────────
        if args.auto_person and not ts.locked and frame_n < 5:
            person_box = detect_person(frame)
            if person_box:
                print(f'[tracker] auto-detected person at {person_box}')
                ts.init_tracker(frame, person_box)
                bridge.send_tracker_status(True, True)

        # ── User selection ─────────────────────────────────────────
        if sel_bbox and not ts.locked:
            ts.init_tracker(frame, sel_bbox)
            sel_bbox = None
            print(f'[tracker] target locked at {ts.bbox}')
            bridge.send_tracker_status(True, True)

        # ── Update tracker ─────────────────────────────────────────
        if ts.locked or (ts.tracker is not None):
            ok, bbox = ts.update(frame)

        # ── Compute RC ─────────────────────────────────────────────
        if ts.locked:
            rc_cmd = ts.compute_rc()
        elif ts.target_lost:
            rc_cmd = {'lr': 0, 'fb': 0, 'ud': 0, 'yaw': 0}
            bridge.send_hover()
            bridge.send_tracker_status(False, True)

        # ── Send RC at 30Hz ────────────────────────────────────────
        now = time.monotonic()
        if ts.locked and now - last_rc >= 0.033:
            bridge.send_rc(**rc_cmd)
            last_rc = now

        # ── Broadcast frame to web UI every 3 frames ──────────────
        if frame_n % 3 == 0:
            disp = draw_osd(frame.copy(), ts, rc_cmd)
            _, jpg = cv2.imencode('.jpg', disp, [cv2.IMWRITE_JPEG_QUALITY, 55])
            b64 = base64.b64encode(jpg.tobytes()).decode()
            bridge.send_track_frame(ts.locked, ts.bbox, b64)

        # ── Display ────────────────────────────────────────────────
        if not args.headless:
            disp = draw_osd(frame.copy(), ts, rc_cmd)

            # Draw selection rect
            if selecting_active and sel_pt1 and sel_pt2:
                cv2.rectangle(disp, sel_pt1, sel_pt2, (255, 255, 0), 1)

            # FPS counter
            frame_n += 1
            if frame_n % 30 == 0:
                fps_val = 30 / (time.monotonic() - fps_t)
                fps_t = time.monotonic()
            cv2.putText(disp, f'{fps_val:.0f}fps', (FRAME_W - 60, FRAME_H - 6),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.4, (80, 80, 80), 1)

            cv2.imshow('Purple Bruce Tracker', disp)
            key = cv2.waitKey(1) & 0xFF

            if key == 27:  # ESC — stop drone, quit
                bridge.send_hover()
                bridge.send_tracker_status(False, False)
                print('[tracker] ESC — hover + quit')
                break
            elif key == ord('q'):
                bridge.send_hover()
                break
            elif key == ord('r'):  # R — reset tracker
                ts.tracker  = None
                ts.locked   = False
                ts.lost_at  = None
                sel_bbox    = None
                bridge.send_hover()
                bridge.send_tracker_status(False, True)
                print('[tracker] reset — draw new selection')
            elif key == ord(' ') and sel_bbox:
                ts.init_tracker(frame, sel_bbox)
                sel_bbox = None

        # ── Timing ────────────────────────────────────────────────
        elapsed_ms = (time.monotonic() - t0) * 1000
        sleep_ms   = max(0, FRAME_MS - elapsed_ms)
        if sleep_ms > 0 and args.headless:
            time.sleep(sleep_ms / 1000)

        frame_n += 1

    if not args.headless:
        cv2.destroyAllWindows()
    if cap:
        cap.release()

# ── Entry ─────────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(
        prog='tracker.py',
        description='Purple Bruce — DJI Mini 4K Autonomous Target Tracker',
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument('--bridge-url',   default=BRIDGE_URL,
                    help=f'Drone bridge WebSocket URL (default: {BRIDGE_URL})')
    ap.add_argument('--speed',        type=int, default=75,
                    help='Max follow speed 0-100 (75 ≈ 30km/h, default: 75)')
    ap.add_argument('--auto-person',  action='store_true',
                    help='Auto-detect first person via HOG detector')
    ap.add_argument('--headless',     action='store_true',
                    help='No display window (target via auto-person or WS)')
    ap.add_argument('--kp-lr',        type=float, default=PID_LR['kP'],
                    help='PID kP for left/right (tune for your drone)')
    args = ap.parse_args()

    PID_LR['kP'] = args.kp_lr

    print(f"""
  ╭────────────────────────────────────────────────╮
  │  PURPLE BRUCE — Autonomous Tracker  v1.0       │
  │  Bridge: {args.bridge_url:<38}│
  │  Max speed: {args.speed}%  (~{args.speed*0.4:.0f} km/h)                   │
  │  Mode: {"auto-person" if args.auto_person else "headless" if args.headless else "interactive (click to select)"}{"":>26}│
  ╰────────────────────────────────────────────────╯
""")
    run(args)

if __name__ == '__main__':
    main()
