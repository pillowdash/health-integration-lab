#!/usr/bin/env python3
"""Send one synthetic HL7 file over MLLP to Mirth. No third-party packages."""
import argparse
import socket
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--host', default='127.0.0.1')
parser.add_argument('--port', type=int, default=2575)
parser.add_argument('--file', default='examples/synthetic-oru.hl7')
args = parser.parse_args()
message = Path(args.file).read_bytes().replace(b'\r\n', b'\r').replace(b'\n', b'\r').strip(b'\r') + b'\r'
with socket.create_connection((args.host, args.port), timeout=10) as connection:
    connection.settimeout(15)
    connection.sendall(b'\x0b' + message + b'\x1c\x0d')
    try:
        response = connection.recv(8192)
        print('MLLP response:', repr(response))
        print('WARNING: an ACK is not necessarily proof of downstream HTTP delivery.')
    except socket.timeout:
        print('No synchronous ACK received; check Mirth response settings and channel logs.')
