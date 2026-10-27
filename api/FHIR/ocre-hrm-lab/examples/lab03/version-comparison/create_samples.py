
import json
from pathlib import Path

base = Path("examples/lab03/version-comparison")

bundle = json.loads(
    Path("examples/lab03/report-0013-r4.json").read_text()
)

# Extract the generated R4 DocumentReference
r4 = next(
    entry["resource"]
    for entry in bundle["entry"]
    if entry["resource"]["resourceType"] == "DocumentReference"
)

# Create a DSTU2 representation for the lab
dstu2 = {
    "resourceType": "DocumentReference",
    "status": r4["status"],
    "type": r4["type"],
    "indexed": r4["date"],
    "subject": r4["subject"],
    "author": r4["author"],
    "content": r4["content"]
}

(base / "document-r4.json").write_text(
    json.dumps(r4, indent=2) + "\n"
)

(base / "document-dstu2.json").write_text(
    json.dumps(dstu2, indent=2) + "\n"
)

print("R4 fields:")
print(list(r4.keys()))

print("\nDSTU2 fields:")
print(list(dstu2.keys()))

