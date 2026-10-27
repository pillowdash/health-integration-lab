cd ~/health-integration-lab/api/FHIR/ocre-hrm-lab

python3 - <<'PY'
from pathlib import Path

source = Path("examples/lab02/missing-mrn.hl7")
target = Path("examples/lab02/missing-mrn-retest.hl7")

data = source.read_bytes()
assert b"SYNTH-OCRE-0003" in data

target.write_bytes(
    data.replace(b"SYNTH-OCRE-0003",
                 b"SYNTH-OCRE-0005")
)
print("Created:", target)
PY
