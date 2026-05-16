#!/usr/bin/env python3
"""
Purple Bruce · DJI Mini 4K  ·  Property Security Patrol  v1.0

Autonomous perimeter patrol for private property.
Drone flies a configurable route, detects intruders, alerts owner via HOCO EQ3.

INSTALL (inside Arch proot):
  pacman -S python-opencv python-websockets python-numpy python-requests

USAGE:
  drone-patrol                    # 8m square perimeter, 3m altitude
  drone-patrol --radius 8 --alt 3 # explicit size/altitude
  drone-patrol --sides 6          # hexagonal route (6 sides)
  drone-patrol --alert-only       # hover in place, detection + alerts only
  drone-patrol --speed 30         # slower patrol (default 40 cm/s)
  drone-patrol --save-dir /tmp    # where to save intruder frames

CONTROLS (window must be focused):
  Q / ESC       land + quit
  P             pause/resume patrol
  S             take manual snapshot
  A             test alert tone

NOTES:
  - Drone must be connected and in SDK mode (run: drone-bridge first)
  - Requires operator token in ~/.purplebruce/operator.txt
  - All detections logged to Purple Bruce soc_alerts + saved as JPEG
  - This tool is for monitoring YOUR private property only
"""

import sys, os, asyncio, time, json, math, base64, argparse, threading, queue
import wave, struct, subprocess, datetime, sqlite3
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

# ── Config ─────────────────────────────────────────────────────────────────────
BRIDGE_URL     = 'ws://127.0.0.1:7778'
SERVER_URL     = 'ws://127.0.0.1:3000'
DB_PATH        = os.path.expanduser('~/purplebruce/purplebruce.db')
TOKEN_PATH     = os.path.expanduser('~/.purplebruce/operator.txt')
DEFAULT_SAVEDIR = os.path.expanduser('~/.purplebruce/patrol_captures')
VIDEO_URL      = 'udp://0.0.0.0:11111'
FRAME_W, FRAME_H = 640, 480   # lower res = faster detection loop

# Detection
HOG_WIN_STRIDE  = (8, 8)
HOG_PADDING     = (4, 4)
HOG_SCALE       = 1.05
HOG_MIN_CONF    = 0.3          # HOG weight threshold
DETECT_EVERY_N  = 5            # run HOG every N frames
ALERT_COOLDOWN  = 10.0         # seconds between repeated alerts for same zone

# Patrol timing
LEG_DURATION    = 8.0          # seconds to fly each leg at default speed
HOVER_AT_CORNER = 1.5          # seconds to hover at each waypoint corner
SCAN_PAUSE      = 3.0          # seconds to pause and scan at each corner

# Arasaka colors (BGR)
A_RED   = (38,   0, 220)
A_GOLD  = (32, 176, 255)
A_WHITE = (220, 220, 220)
A_DARK  = ( 10,  10,  10)
A_GREEN = ( 50, 210,  50)
A_GRAY  = ( 80,  80,  80)

# ── Operator token ─────────────────────────────────────────────────────────────
def load_token() -> str:
    try:
        return open(TOKEN_PATH).read().strip()
    except Exception:
        return ''

# ── Audio alerts ───────────────────────────────────────────────────────────────
def _tone(freq: int, dur: float, vol: float = 0.6):
    def _play():
        try:
            rate, fn = 22050, '/tmp/_pb_patrol_alert.wav'
            n = int(rate * dur)
            with wave.open(fn, 'w') as wf:
                wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(rate)
                for i in range(n):
                    fade = min(i, n - i) / max(1, min(600, n // 4))
                    v = int(32000 * vol * min(1.0, fade) * math.sin(2 * math.pi * freq * i / rate))
                    wf.writeframes(struct.pack('<h', v))
            subprocess.run(['paplay', fn], stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, timeout=4)
        except Exception:
            pass
    threading.Thread(target=_play, daemon=True).start()

def alert_intruder():
    """Distinctive 3-pulse alert — plays through HOCO EQ3."""
    def _seq():
        for freq in [880, 1047, 1319]:   # A5 C6 E6 — ascending alarm chord
            _tone(freq, 0.18)
            time.sleep(0.22)
    threading.Thread(target=_seq, daemon=True).start()

def alert_clear():
    _tone(523, 0.15)   # C5 — all clear

# ── Database logging ───────────────────────────────────────────────────────────
def log_alert(severity: str, detail: str, frame_path: str = ''):
    """Write detection to Purple Bruce soc_alerts table."""
    try:
        con = sqlite3.connect(DB_PATH, timeout=5)
        con.execute(
            "INSERT INTO soc_alerts (severity, type, detail, response, timestamp) "
            "VALUES (?, ?, ?, ?, ?)",
            (severity, 'patrol_detection', detail,
             f'frame:{frame_path}' if frame_path else 'no_frame',
             datetime.datetime.utcnow().isoformat())
        )
        con.commit()
        con.close()
    except Exception as e:
        print(f'[patrol] db log failed: {e}')

# ── Save intruder frame ────────────────────────────────────────────────────────
def save_frame(frame: np.ndarray, save_dir: str, zone: str) -> str:
    os.makedirs(save_dir, exist_ok=True)
    ts  = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    fn  = os.path.join(save_dir, f'intruder_{ts}_{zone}.jpg')
    cv2.imwrite(fn, frame)
    return fn

# ── Person detector ────────────────────────────────────────────────────────────
class PersonDetector:
    def __init__(self):
        self._hog = cv2.HOGDescriptor()
        self._hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())

    def detect(self, frame: np.ndarray) -> List[Tuple]:
        """Return list of (x,y,w,h) bboxes for detected people."""
        small   = cv2.resize(frame, (FRAME_W // 2, FRAME_H // 2))
        boxes, weights = self._hog.detectMultiScale(
            small, winStride=HOG_WIN_STRIDE, padding=HOG_PADDING, scale=HOG_SCALE
        )
        results = []
        if len(boxes) > 0:
            for i, (x, y, w, h) in enumerate(boxes):
                if float(weights[i]) >= HOG_MIN_CONF:
                    results.append((x * 2, y * 2, w * 2, h * 2))
        return results

# ── Patrol route generator ─────────────────────────────────────────────────────
def build_patrol_route(sides: int, leg_m: float, alt_m: float) -> List[dict]:
    """
    Build a regular polygon patrol route as relative move commands.
    Returns list of {cmd, x, y, z, speed} dicts for the drone bridge.

    Coordinate system (DJI SDK):
      x = forward (cm), y = left (cm), z = up (cm)
    """
    leg_cm = int(leg_m * 100)
    alt_cm = int(alt_m * 100)
    angle_step = 360.0 / sides
    routes = []

    # Initial takeoff + climb to patrol altitude
    routes.append({'phase': 'takeoff', 'cmd': 'takeoff'})
    routes.append({'phase': 'climb',   'cmd': 'up', 'dist': alt_cm})

    # Fly the polygon
    heading = 0.0
    for i in range(sides):
        rad = math.radians(heading)
        dx  = int(leg_cm * math.cos(rad))
        dy  = int(leg_cm * math.sin(rad))
        # DJI 'go' command: x=forward, y=left, z=up (relative, cm)
        routes.append({
            'phase': f'leg_{i}',
            'cmd':   'go',
            'x':     dx,
            'y':     dy,
            'z':     0,
            'speed': 40,       # cm/s — slow, thorough scan
        })
        routes.append({'phase': f'scan_{i}', 'cmd': 'hover', 'dwell': SCAN_PAUSE})
        heading += angle_step

    return routes

# ── Drone WebSocket bridge client ──────────────────────────────────────────────
class DroneClient:
    def __init__(self, bridge_url: str):
        self.url   = bridge_url
        self._loop = asyncio.new_event_loop()
        self._t    = threading.Thread(target=self._run, daemon=True)
        self._q: queue.Queue = queue.Queue()
        self.telemetry: dict = {}
        self.connected = False

    def start(self):
        self._t.start()
        time.sleep(1.0)   # let loop start

    def send(self, msg: dict):
        self._q.put(msg)

    def cmd(self, command: str, params: dict = None):
        self.send({'action': 'command', 'cmd': command, 'params': params or {}})

    def _run(self):
        asyncio.set_event_loop(self._loop)
        self._loop.run_until_complete(self._connect_loop())

    async def _connect_loop(self):
        while True:
            try:
                async with websockets.connect(self.url) as ws:
                    self.connected = True
                    print('[patrol] bridge connected')
                    await asyncio.wait(
                        [asyncio.create_task(self._recv(ws)),
                         asyncio.create_task(self._send(ws))],
                        return_when=asyncio.FIRST_COMPLETED
                    )
            except Exception as e:
                self.connected = False
                print(f'[patrol] bridge error: {e} — retry 5s')
                await asyncio.sleep(5)

    async def _recv(self, ws):
        async for raw in ws:
            try:
                msg = json.loads(raw)
                if msg.get('type') == 'telemetry':
                    self.telemetry = msg.get('data', {})
            except Exception:
                pass

    async def _send(self, ws):
        loop = asyncio.get_event_loop()
        while True:
            try:
                msg = await loop.run_in_executor(None, self._q.get, True, 0.05)
                await ws.send(json.dumps(msg))
            except queue.Empty:
                pass
            except Exception:
                break

# ── HUD overlay ────────────────────────────────────────────────────────────────
def draw_hud(frame: np.ndarray, zone: str, count: int, detections: List[Tuple],
             paused: bool, telem: dict, alert_active: bool) -> np.ndarray:
    out  = frame.copy()
    h, w = out.shape[:2]

    # Top bar
    cv2.rectangle(out, (0, 0), (w, 40), A_DARK, -1)
    cv2.line(out, (0, 40), (w, 40), A_RED, 1)

    status_col = A_RED if alert_active else (A_GOLD if paused else A_GREEN)
    status_str = "INTRUDER" if alert_active else ("PAUSED" if paused else "PATROL")
    cv2.putText(out, "ARASAKA SECURITY",  (8, 14), cv2.FONT_HERSHEY_SIMPLEX, 0.42, A_GRAY,  1)
    cv2.putText(out, status_str,          (8, 32), cv2.FONT_HERSHEY_SIMPLEX, 0.55, status_col, 2)

    bat = telem.get('battery', '--')
    alt = telem.get('altitude', '--')
    cv2.putText(out, f"ZONE:{zone}  BAT:{bat}%  ALT:{alt}m",
                (w - 260, 22), cv2.FONT_HERSHEY_SIMPLEX, 0.40, A_WHITE, 1)

    # Draw detection bboxes
    for (x, y, bw, bh) in detections:
        cv2.rectangle(out, (x, y), (x + bw, y + bh), A_RED, 2)
        cv2.putText(out, "PERSON", (x, y - 6),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, A_RED, 1)
        # Corner ticks
        tk = 12
        for rx, ry in [(x,y),(x+bw,y),(x,y+bh),(x+bw,y+bh)]:
            dx = 1 if rx == x else -1
            dy = 1 if ry == y else -1
            cv2.line(out, (rx, ry), (rx + tk*dx, ry), A_RED, 2)
            cv2.line(out, (rx, ry), (rx, ry + tk*dy), A_RED, 2)

    # Bottom bar
    cv2.rectangle(out, (0, h - 28), (w, h), A_DARK, -1)
    cv2.line(out, (0, h - 28), (w, h - 28), A_RED, 1)
    cv2.putText(out, f"Detections today: {count}",
                (8, h - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.40, A_WHITE, 1)
    cv2.putText(out, "Q=quit  P=pause  S=snapshot  A=test alert",
                (w - 330, h - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.36, A_GRAY, 1)

    return out

# ── Main patrol loop ───────────────────────────────────────────────────────────
def run(args):
    token    = load_token()
    detector = PersonDetector()
    drone    = DroneClient(args.bridge_url)
    drone.start()

    os.makedirs(args.save_dir, exist_ok=True)

    if not drone.connected:
        print('[patrol] waiting for bridge connection...')
        for _ in range(10):
            time.sleep(1)
            if drone.connected:
                break
        if not drone.connected:
            print('[patrol] ERROR: cannot connect to drone bridge')
            print('         Run: drone-bridge  (in a separate terminal)')
            sys.exit(1)

    # Build patrol route
    route = build_patrol_route(
        sides=args.sides,
        leg_m=args.radius,
        alt_m=args.alt,
    )

    # Video
    cap = cv2.VideoCapture(VIDEO_URL)
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    if not cap.isOpened():
        cap = cv2.VideoCapture(0)

    if not args.headless:
        cv2.namedWindow('ARASAKA SECURITY PATROL', cv2.WINDOW_NORMAL)

    # State
    paused         = False
    total_detected = 0
    zone           = 'INIT'
    alert_active   = False
    last_alert_t   = {}   # zone → last alert time
    frame_n        = 0
    route_idx      = 0
    leg_start_t    = time.monotonic()
    phase          = 'pre_launch' if not args.alert_only else 'scanning'
    dwell_until    = 0.0

    print(f"""
  ╔═════════════════════════════════════════════════════╗
  ║  A R A S A K A   S E C U R I T Y   P A T R O L    ║
  ║  Purple Bruce · Property Guard · v1.0               ║
  ║  Route: {args.sides}-sided polygon  {args.radius}m radius  {args.alt}m altitude{'':>10}║
  ║  Save : {args.save_dir:<44}║
  ╚═════════════════════════════════════════════════════╝
""")

    if not args.alert_only:
        print('[patrol] sending takeoff command...')
        drone.cmd('takeoff')
        time.sleep(3)
        drone.cmd('up', {'dist': int(args.alt * 100)})
        time.sleep(2)
        print(f'[patrol] at altitude {args.alt}m — patrol route active')
    else:
        print('[patrol] alert-only mode — drone stays in place, monitoring')

    # Navigation thread (non-blocking leg execution)
    nav_q: queue.Queue = queue.Queue()

    def nav_thread():
        if args.alert_only:
            return
        for step in route:
            if step['cmd'] == 'takeoff':
                continue   # already done above
            if step['cmd'] == 'up':
                continue   # already done above
            nav_q.put(step)

    nav = threading.Thread(target=nav_thread, daemon=True)
    nav.start()

    def execute_nav_step(step: dict):
        nonlocal zone, dwell_until
        zone = step.get('phase', zone).upper()
        if step['cmd'] == 'hover':
            drone.cmd('hover')
            dwell_until = time.monotonic() + step.get('dwell', HOVER_AT_CORNER)
        elif step['cmd'] == 'go':
            drone.cmd('go', {
                'x': step['x'], 'y': step['y'], 'z': step['z'],
                'speed': step.get('speed', 40)
            })
            dwell_until = time.monotonic() + LEG_DURATION

    current_step: Optional[dict] = None
    step_done = True

    while True:
        t0 = time.monotonic()

        # Read video frame
        ret, frame = cap.read()
        if not ret or frame is None:
            frame = np.zeros((FRAME_H, FRAME_W, 3), dtype=np.uint8)
        else:
            frame = cv2.resize(frame, (FRAME_W, FRAME_H))

        # ── Navigation scheduler ───────────────────────────────────────────────
        if not paused and not args.alert_only:
            if step_done or time.monotonic() >= dwell_until:
                try:
                    current_step = nav_q.get_nowait()
                    execute_nav_step(current_step)
                    step_done = False
                except queue.Empty:
                    # Route complete — loop it
                    nav = threading.Thread(target=nav_thread, daemon=True)
                    nav.start()
                if time.monotonic() >= dwell_until:
                    step_done = True

        # ── Person detection ───────────────────────────────────────────────────
        detections = []
        if frame_n % DETECT_EVERY_N == 0:
            detections = detector.detect(frame)

        if detections:
            now = time.monotonic()
            last = last_alert_t.get(zone, 0)
            if now - last >= ALERT_COOLDOWN:
                last_alert_t[zone] = now
                total_detected += len(detections)
                alert_active    = True

                # Save annotated frame
                annotated = frame.copy()
                for (x, y, bw, bh) in detections:
                    cv2.rectangle(annotated, (x, y), (x+bw, y+bh), A_RED, 2)
                frame_path = save_frame(annotated, args.save_dir, zone)

                detail = (f"ZONE:{zone}  count:{len(detections)}  "
                          f"bat:{drone.telemetry.get('battery','?')}%  "
                          f"alt:{drone.telemetry.get('altitude','?')}m  "
                          f"frame:{frame_path}")
                print(f'[patrol] ⚠ PERSON DETECTED  {detail}')

                alert_intruder()   # 3-pulse alarm through HOCO EQ3
                log_alert('HIGH', detail, frame_path)

                # Hover to get a clear shot
                if not args.alert_only:
                    drone.cmd('hover')
                    dwell_until = time.monotonic() + SCAN_PAUSE
        else:
            alert_active = False

        # ── Display ────────────────────────────────────────────────────────────
        if not args.headless:
            hud = draw_hud(frame, zone, total_detected, detections,
                           paused, drone.telemetry, alert_active)
            cv2.imshow('ARASAKA SECURITY PATROL', hud)
            key = cv2.waitKey(1) & 0xFF

            if key in (27, ord('q')):
                print('[patrol] landing...')
                drone.cmd('land')
                time.sleep(3)
                break
            elif key == ord('p'):
                paused = not paused
                if paused:
                    drone.cmd('hover')
                    print('[patrol] paused')
                else:
                    print('[patrol] resumed')
            elif key == ord('s'):
                fp = save_frame(frame, args.save_dir, 'manual')
                print(f'[patrol] snapshot saved: {fp}')
            elif key == ord('a'):
                alert_intruder()
                print('[patrol] test alert played')

        frame_n += 1
        elapsed = (time.monotonic() - t0) * 1000
        sleep_ms = max(0, 33 - elapsed)
        if sleep_ms > 1:
            time.sleep(sleep_ms / 1000)

    if not args.headless:
        cv2.destroyAllWindows()
    cap.release()
    print(f'[patrol] session ended. Total detections: {total_detected}')
    print(f'         Frames saved in: {args.save_dir}')

# ── Entry ──────────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(
        prog='patrol.py',
        description='Purple Bruce — Property Security Patrol v1.0'
    )
    ap.add_argument('--bridge-url', default=BRIDGE_URL)
    ap.add_argument('--radius',     type=float, default=8.0,
                    help='Patrol perimeter size in metres (default: 8)')
    ap.add_argument('--alt',        type=float, default=3.0,
                    help='Patrol altitude in metres (default: 3)')
    ap.add_argument('--sides',      type=int,   default=4,
                    help='Polygon sides: 4=square, 6=hexagon (default: 4)')
    ap.add_argument('--speed',      type=int,   default=40,
                    help='Patrol speed cm/s (default: 40)')
    ap.add_argument('--alert-only', action='store_true',
                    help='Hover in place, detection + alerts only (no route)')
    ap.add_argument('--headless',   action='store_true',
                    help='No display window')
    ap.add_argument('--save-dir',   default=DEFAULT_SAVEDIR,
                    help='Directory to save intruder capture frames')
    args = ap.parse_args()
    run(args)

if __name__ == '__main__':
    main()
