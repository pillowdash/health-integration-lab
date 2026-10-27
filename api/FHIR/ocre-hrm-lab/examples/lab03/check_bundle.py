
import json
import base64
from pathlib import Path

path = Path("examples/lab03/report-0013-r4.json")
bundle = json.loads(path.read_text())

assert bundle["resourceType"] == "Bundle"
assert bundle["type"] == "collection"

entries = {
    entry["resource"]["resourceType"]: entry
    for entry in bundle["entry"]
}

assert len(bundle["entry"]) == 3
assert set(entries) == {
    "Patient", "Practitioner", "DocumentReference"
}

patient_entry = entries["Patient"]
doctor_entry = entries["Practitioner"]
document_entry = entries["DocumentReference"]

patient = patient_entry["resource"]
doctor = doctor_entry["resource"]
document = document_entry["resource"]

# Verify patient and physician identifiers
assert patient["identifier"][0]["value"] == "TEST123"
assert doctor["identifier"][0]["value"] == "P100"

# Verify Bundle-local references
assert document["subject"]["reference"] == patient_entry["fullUrl"]
assert document["author"][0]["reference"] == doctor_entry["fullUrl"]

# Verify document metadata
assert document["status"] == "current"
assert document["type"]["coding"][0]["code"] == "18842-5"

# Decode and verify clinical report content
attachment = document["content"][0]["attachment"]
assert attachment["contentType"] == "text/plain"

report_text = base64.b64decode(
    attachment["data"], validate=True
).decode("utf-8")

assert report_text == (
    "Synthetic discharge summary for lab. No real PHI."
)

print("PASS: FHIR Bundle structure")
print("PASS: Patient MRN mapping")
print("PASS: Practitioner mapping")
print("PASS: Patient and author references")
print("PASS: DocumentReference metadata")
print("PASS: Base64 report content")
print()
print("Clinical report:", report_text)

