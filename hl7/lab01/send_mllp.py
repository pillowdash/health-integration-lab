import socket
import sys
from pathlib import Path

#HOST = "127.0.0.1"
#PORT = 2575



filename = sys.argv[1] if len(sys.argv) > 1 else "ADT_A01.hl7"

HOST = sys.argv[2] if len(sys.argv) > 2 else "127.0.0.1"
PORT = int(sys.argv[3]) if len(sys.argv) > 3 else 2575

# Read HL7 file
text = Path(filename).read_text()

# HL7 segments should be separated by CR (0x0D)
message = (
    text.replace("\r\n", "\n")
        .replace("\r", "\n")
        .replace("\n", "\r")
        .rstrip("\r")
    + "\r"
)

# MLLP framing:
#
# Start Block = VT  = 0x0B
# End Block   = FS  = 0x1C
# End Data    = CR  = 0x0D
#
payload = (
    b"\x0b"
    + message.encode("utf-8")
    + b"\x1c\x0d"
)

print(f"Connecting to {HOST}:{PORT} ...")

print("\n--- Sending HL7 ---")
print(message.replace("\r", "\n"))

with socket.create_connection((HOST, PORT), timeout=10) as sock:

    sock.sendall(payload)

    response = b""

    while b"\x1c\x0d" not in response:
        chunk = sock.recv(4096)

        if not chunk:
            break

        response += chunk


# Strip MLLP framing from ACK
if response.startswith(b"\x0b"):
    response = response[1:]

if response.endswith(b"\x1c\x0d"):
    response = response[:-2]


print("\n--- Received ACK ---")

print(
    response
    .decode("utf-8", errors="replace")
    .replace("\r", "\n")
)
