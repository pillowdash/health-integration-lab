
mkdir -p examples/lab02

python3 - <<'PY'
from pathlib import Path

source = Path("examples/synthetic-oru.hl7").read_bytes()
lines = source.replace(b"\r", b"\n").decode().splitlines()
original = [line.split("|") for line in lines if line]

def create(name, control_id, change):
    segments = [fields.copy() for fields in original]

    msh = next(s for s in segments if s[0] == "MSH")
    msh[9] = control_id

    change(segments)

    content = "\r".join("|".join(s) for s in segments) + "\r"
    Path("examples/lab02", name).write_bytes(content.encode())

def remove_mrn(segments):
    pid = next(s for s in segments if s[0] == "PID")
    pid[3] = ""

def change_physician(segments):
    obr = next(s for s in segments if s[0] == "OBR")
    obr[16] = "P999^JONES^BOB"

create("missing-mrn.hl7", "SYNTH-OCRE-0003", remove_mrn)
create("wrong-physician.hl7", "SYNTH-OCRE-0004", change_physician)

print("Created two HL7 test messages.")
PY

