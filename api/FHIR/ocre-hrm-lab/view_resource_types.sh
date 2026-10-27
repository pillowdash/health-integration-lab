python3 - <<'PY'
import json

with open("examples/lab03/report-0013-r4.json") as f:
    bundle = json.load(f)

print("FHIR resource:", bundle["resourceType"])
print("Bundle type:", bundle["type"])

for entry in bundle["entry"]:
    r = entry["resource"]
    print(r["resourceType"], r["id"])
PY
