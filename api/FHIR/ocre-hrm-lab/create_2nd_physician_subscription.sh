python3 - <<'PY'
import json
from pathlib import Path

base = Path("examples/lab04")

p100 = json.loads(
    (base / "subscription-p100.json").read_text()
)

p999 = p100.copy()
p999["id"] = "physician-p999"
p999["reason"] = "Lab subscription for physician P999 clinical reports"

# Deep-copy nested filter data before modifying
p999 = json.loads(json.dumps(p999))
p999["_criteria"]["extension"][0]["valueString"] = "physician-id=P999"

(base / "subscription-p999.json").write_text(
    json.dumps(p999, indent=2) + "\n"
)

print("Created physician P999 subscription")
PY
