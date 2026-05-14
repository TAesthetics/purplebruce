#!/usr/bin/env python3
"""
DJI Mini 4K — Purple Bruce Drone Bridge  v1.0
Connects to drone via WiFi, exposes WebSocket API on port 7778

Run from TERMUX (outside proot) for direct WiFi access:
  python3 ~/purplebruce/netrunner/drone/mini4k.py

Or from Arch proot with host networking:
  proot-distro login archlinux
  python3 ~/purplebruce/netrunner/drone/mini4k.py

DJI Mini 4K WiFi SDK mode:
  1. Power on drone
  2. On RC-N1 controller: go to C button → More → WiFi Settings → WiFi Bridge
     OR hold power button 3s → activate hotspot
  3. Connect to "DJI_MINI_<serial>" WiFi from Termux
  4. Run this script → connect from Purple Bruce web UI

Note: Full autonomous waypoint missions require the DJI Mobile SDK (Android app).
      This bridge supports manual real-time control via UDP SDK protocol.
"""

import asyncio
import json
import socket
import subprocess
import threading
import time
import sys
import os
import re
from typing import Optional

try:
    import websockets
except ImportError:
    print("[!] Install websockets: pip install websockets")
    sys.exit(1)

# ── DJI UDP SDK Protocol ports ───────────────────────────────────────────────
# Compatible with DJI Tello SDK v2 and DJI Mini WiFi bridge mode
CMD_PORT   = 8889   # UDP send → drone
STATE_PORT = 8890   # UDP receive ← drone telemetry
VIDEO_PORT = 11111  # UDP receive ← H264 stream

WS_PORT = 7778      # local WebSocket server for Purple Bruce

# Known DJI drone IPs in WiFi AP mode
DRONE_IPS = ['192.168.2.1', '192.168.0.1', '192.168.10.1', '192.168.1.1']

# DJI WiFi SSID patterns
DJI_SSID_RE = re.compile(r'DJI[-_]|TELLO[-_]|PHANTOM|MAVIC|MINI[-_]|SPARK[-_]', re.IGNORECASE)

# ── State ─────────────────────────────────────────────────────────────────────
state = {
    'connected': False,
    'ip': None,
    'battery': None,
    'altitude': None,
    'speed_h': None,
    'speed_v': None,
    'lat': None,
    'lon': None,
    'heading': None,
    'temp_low': None,
    'temp_high': None,
    'tof': None,
    'flight_time': 0,
    'sdk': None,
    'sn': None,
    'mode': 'IDLE',  # IDLE, HOVERING, FLYING, LANDING
    'error': None,
}

sock_cmd   : Optional[socket.socket] = None
sock_state : Optional[socket.socket] = None
connected_clients = set()
telem_task = None

# ── WiFi scanning ─────────────────────────────────────────────────────────────
def scan_wifi() -> list[dict]:
    """Scan for DJI WiFi networks."""
    networks = []

    # Try nmcli (available in Arch proot + Termux with termux-api)
    try:
        out = subprocess.check_output(
            ['nmcli', '-t', '-f', 'SSID,SIGNAL,SECURITY', 'dev', 'wifi', 'list'],
            timeout=10, stderr=subprocess.DEVNULL
        ).decode()
        for line in out.strip().split('\n'):
            parts = line.split(':')
            if len(parts) >= 2:
                ssid = parts[0].strip()
                signal = parts[1].strip() if len(parts) > 1 else '?'
                if ssid and DJI_SSID_RE.search(ssid):
                    networks.append({'ssid': ssid, 'signal': signal, 'source': 'nmcli'})
        if networks:
            return networks
    except Exception:
        pass

    # Try iw (common on Linux)
    try:
        out = subprocess.check_output(
            ['iw', 'dev'], timeout=5, stderr=subprocess.DEVNULL
        ).decode()
        ifaces = re.findall(r'Interface (\S+)', out)
        for iface in ifaces:
            try:
                scan = subprocess.check_output(
                    ['iw', iface, 'scan'], timeout=15, stderr=subprocess.DEVNULL
                ).decode()
                for ssid in re.findall(r'SSID: (.+)', scan):
                    if DJI_SSID_RE.search(ssid):
                        networks.append({'ssid': ssid.strip(), 'signal': '?', 'source': 'iw'})
            except Exception:
                pass
        if networks:
            return networks
    except Exception:
        pass

    # Try /proc/net/wireless + /proc/net/arp for connected network
    try:
        ifaces_raw = open('/proc/net/wireless').read()
        for line in ifaces_raw.split('\n')[2:]:
            if line.strip():
                iface = line.split(':')[0].strip()
                try:
                    ssid = subprocess.check_output(
                        ['iwgetid', iface, '-r'], timeout=5, stderr=subprocess.DEVNULL
                    ).decode().strip()
                    if ssid and DJI_SSID_RE.search(ssid):
                        networks.append({'ssid': ssid, 'signal': '?', 'source': 'iwgetid', 'connected': True})
                except Exception:
                    pass
    except Exception:
        pass

    return networks


def detect_drone_ip() -> Optional[str]:
    """Try to find drone IP by pinging known addresses."""
    for ip in DRONE_IPS:
        try:
            result = subprocess.run(
                ['ping', '-c', '1', '-W', '1', ip],
                capture_output=True, timeout=3
            )
            if result.returncode == 0:
                return ip
        except Exception:
            pass
    return None


# ── UDP control ───────────────────────────────────────────────────────────────
def send_cmd(cmd: str) -> str:
    """Send UDP command to drone, return response."""
    global sock_cmd
    if not sock_cmd or not state['connected']:
        return 'error: not connected'
    try:
        sock_cmd.sendto(cmd.encode(), (state['ip'], CMD_PORT))
        sock_cmd.settimeout(3.0)
        data, _ = sock_cmd.recvfrom(1024)
        return data.decode().strip()
    except socket.timeout:
        return 'timeout'
    except Exception as e:
        return f'error: {e}'


def connect_drone(ip: str) -> bool:
    """Establish UDP connection and enter SDK mode."""
    global sock_cmd, sock_state, state

    try:
        # Command socket
        sock_cmd = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock_cmd.bind(('', 9000))
        state['ip'] = ip

        # Init SDK mode
        resp = send_cmd('command')
        if resp not in ('ok', 'OK'):
            # Try without SDK init (some models auto-accept)
            print(f'[drone] SDK init response: {resp} (continuing...)')

        state['connected'] = True
        state['mode'] = 'HOVERING'

        # Query drone info
        sdk = send_cmd('sdk?')
        sn  = send_cmd('sn?')
        bat = send_cmd('battery?')
        state['sdk'] = sdk if sdk not in ('timeout', '') else None
        state['sn']  = sn  if sn  not in ('timeout', '') else None
        if bat.isdigit():
            state['battery'] = int(bat)

        # Start telemetry receiver
        sock_state = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock_state.bind(('', STATE_PORT))
        sock_state.settimeout(2.0)
        threading.Thread(target=recv_telemetry, daemon=True).start()

        print(f'[drone] ✔ Connected to {ip} | SDK:{state["sdk"]} SN:{state["sn"]} bat:{state["battery"]}%')
        return True

    except Exception as e:
        state['error'] = str(e)
        print(f'[drone] ✘ Connect failed: {e}')
        return False


def disconnect_drone():
    """Gracefully disconnect."""
    global sock_cmd, sock_state
    if state['connected']:
        send_cmd('land')
        time.sleep(1)
    state['connected'] = False
    state['mode'] = 'IDLE'
    for s in [sock_cmd, sock_state]:
        try:
            if s: s.close()
        except Exception:
            pass
    sock_cmd = sock_state = None


def recv_telemetry():
    """Thread: receive and parse drone state UDP packets."""
    while state['connected'] and sock_state:
        try:
            data, _ = sock_state.recvfrom(1024)
            parse_state(data.decode())
        except socket.timeout:
            pass
        except Exception:
            break


def parse_state(raw: str):
    """Parse DJI/Tello SDK state string into state dict."""
    # Format: pitch:0;roll:0;yaw:-30;vgx:0;vgy:0;vgz:0;templ:79;temph:83;
    #         tof:10;h:0;bat:67;baro:-0.73;time:0;agx:-18.00;agy:4.00;agz:-998.00;
    for kv in raw.strip().rstrip(';').split(';'):
        if ':' not in kv:
            continue
        k, v = kv.split(':', 1)
        try:
            val = float(v)
            if k == 'bat':   state['battery']  = int(val)
            elif k == 'h':   state['altitude']  = val
            elif k == 'vgx': state['speed_h']   = abs(val)
            elif k == 'vgz': state['speed_v']   = abs(val)
            elif k == 'yaw': state['heading']   = val
            elif k == 'templ': state['temp_low']  = val
            elif k == 'temph': state['temp_high'] = val
            elif k == 'tof':   state['tof']       = val
            elif k == 'time':  state['flight_time']= int(val)
        except Exception:
            pass


# ── Command dispatcher ────────────────────────────────────────────────────────
SPEED = 50  # cm/s default

COMMANDS = {
    'takeoff':        lambda p: send_cmd('takeoff'),
    'land':           lambda p: send_cmd('land'),
    'emergency':      lambda p: send_cmd('emergency'),
    'hover':          lambda p: send_cmd('stop'),
    'up':             lambda p: send_cmd(f'up {p.get("dist", 50)}'),
    'down':           lambda p: send_cmd(f'down {p.get("dist", 50)}'),
    'forward':        lambda p: send_cmd(f'forward {p.get("dist", 50)}'),
    'back':           lambda p: send_cmd(f'back {p.get("dist", 50)}'),
    'left':           lambda p: send_cmd(f'left {p.get("dist", 50)}'),
    'right':          lambda p: send_cmd(f'right {p.get("dist", 50)}'),
    'cw':             lambda p: send_cmd(f'cw {p.get("deg", 90)}'),
    'ccw':            lambda p: send_cmd(f'ccw {p.get("deg", 90)}'),
    'flip':           lambda p: send_cmd(f'flip {p.get("dir", "f")}'),
    'speed':          lambda p: send_cmd(f'speed {p.get("val", SPEED)}'),
    'streamon':       lambda p: send_cmd('streamon'),
    'streamoff':      lambda p: send_cmd('streamoff'),
    'battery':        lambda p: send_cmd('battery?'),
    'altitude':       lambda p: send_cmd('height?'),
    'go':             lambda p: send_cmd(f'go {p["x"]} {p["y"]} {p["z"]} {p.get("speed", SPEED)}'),
}


def dispatch_command(cmd: str, params: dict) -> str:
    fn = COMMANDS.get(cmd)
    if fn:
        return fn(params)
    # passthrough raw SDK command
    return send_cmd(cmd)


# ── WebSocket server ──────────────────────────────────────────────────────────
async def ws_handler(websocket):
    connected_clients.add(websocket)
    print(f'[ws] client connected ({len(connected_clients)} total)')
    try:
        # Send current state on connect
        await websocket.send(json.dumps({'type': 'drone_status', 'data': dict(state)}))

        async for raw in websocket:
            try:
                msg = json.loads(raw)
                action = msg.get('type') or msg.get('action', '')

                if action == 'scan':
                    await websocket.send(json.dumps({'type': 'scan_start'}))
                    networks = scan_wifi()
                    ip = detect_drone_ip()
                    await websocket.send(json.dumps({
                        'type': 'scan_result',
                        'networks': networks,
                        'detected_ip': ip,
                    }))

                elif action == 'connect':
                    ip = msg.get('ip') or detect_drone_ip()
                    if not ip:
                        await websocket.send(json.dumps({'type': 'error', 'msg': 'No drone IP found. Connect to DJI WiFi first.'}))
                        continue
                    await websocket.send(json.dumps({'type': 'connecting', 'ip': ip}))
                    ok = connect_drone(ip)
                    await broadcast_all({'type': 'drone_status', 'data': dict(state)})
                    if not ok:
                        await websocket.send(json.dumps({'type': 'error', 'msg': f'Failed to connect: {state["error"]}'}))

                elif action == 'disconnect':
                    disconnect_drone()
                    await broadcast_all({'type': 'drone_status', 'data': dict(state)})

                elif action == 'command':
                    cmd = msg.get('cmd', '')
                    params = msg.get('params', {})
                    resp = dispatch_command(cmd, params)
                    await broadcast_all({'type': 'cmd_response', 'cmd': cmd, 'resp': resp})

                elif action == 'get_status':
                    await websocket.send(json.dumps({'type': 'drone_status', 'data': dict(state)}))

            except json.JSONDecodeError:
                pass
    except Exception as e:
        print(f'[ws] client error: {e}')
    finally:
        connected_clients.discard(websocket)
        print(f'[ws] client disconnected ({len(connected_clients)} total)')


async def broadcast_all(msg: dict):
    data = json.dumps(msg)
    for ws in list(connected_clients):
        try:
            await ws.send(data)
        except Exception:
            pass


async def telemetry_broadcast_loop():
    """Periodically push telemetry to all WS clients."""
    while True:
        if connected_clients and state['connected']:
            await broadcast_all({'type': 'telemetry', 'data': dict(state)})
        await asyncio.sleep(0.5)


async def main():
    print(f"""
╔══════════════════════════════════════════╗
║  DJI Mini 4K Bridge — Purple Bruce v1.0  ║
║  WebSocket: ws://127.0.0.1:{WS_PORT}        ║
╚══════════════════════════════════════════╝

  Connect drone WiFi first, then open Purple Bruce → Drone panel
  Or: use the Scan button in the web UI
""")
    async with websockets.serve(ws_handler, '127.0.0.1', WS_PORT):
        await telemetry_broadcast_loop()


if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        disconnect_drone()
        print('\n[drone] bridge stopped')
