#!/usr/bin/env python3
"""
Native Messaging host.
register.py ↔ Chrome Extension 사이의 JSON 브릿지.

프로토콜: 4바이트 little-endian 길이 + UTF-8 JSON
"""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path


def send(msg: dict) -> None:
    data = json.dumps(msg, ensure_ascii=False).encode()
    sys.stdout.buffer.write(struct.pack('<I', len(data)))
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()


def recv() -> dict:
    raw_len = sys.stdin.buffer.read(4)
    if len(raw_len) < 4:
        raise EOFError
    length = struct.unpack('<I', raw_len)[0]
    return json.loads(sys.stdin.buffer.read(length))


def parse_args() -> dict:
    args = sys.argv[1:]
    result: dict = {}
    i = 0
    while i < len(args):
        if args[i].startswith('--') and i + 1 < len(args):
            key = args[i][2:].replace('-', '_')
            result[key] = args[i + 1]
            i += 2
        else:
            i += 1
    return result


def main() -> None:
    args = parse_args()
    step       = args.get('step')
    config     = json.loads(args.get('config', '{}'))
    app_id     = args.get('app_id')
    developer_id = args.get('developer_id')

    # Extension으로 명령 전달
    send({'step': step, 'config': config, 'app_id': app_id, 'developer_id': developer_id})

    # Extension으로부터 결과 수신
    try:
        result = recv()
    except (EOFError, json.JSONDecodeError) as e:
        result = {'success': False, 'app_id': None, 'message': str(e)}

    # register.py가 읽는 stdout JSON 출력
    print(json.dumps(result, ensure_ascii=False))
    sys.exit(0 if result.get('success') else 1)


if __name__ == '__main__':
    main()
