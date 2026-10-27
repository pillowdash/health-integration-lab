
import json
from pathlib import Path

base = Path("examples/lab04")

subscriptions = [
    json.loads((base / "subscription-p100.json").read_text()),
    json.loads((base / "subscription-p999.json").read_text())
]

def matches(subscription, event):
    extensions = subscription["_criteria"]["extension"]

    filters = {}
    for extension in extensions:
        key, value = extension["valueString"].split("=", 1)
        filters[key] = value

    return (
        filters["physician-id"] == event["physicianId"]
        and filters["report-code"] == event["reportCode"]
    )

events = [
    {"physicianId": "P100", "reportCode": "18842-5"},
    {"physicianId": "P999", "reportCode": "18842-5"},
    {"physicianId": "P100", "reportCode": "99999-1"}
]

expected = [
    ["physician-p100"],
    ["physician-p999"],
    []
]

for event, wanted in zip(events, expected):
    matched = [
        sub["id"]
        for sub in subscriptions
        if matches(sub, event)
    ]

    assert matched == wanted, (event, matched, wanted)

    print(
        f"Event {event['physicianId']} / "
        f"{event['reportCode']} -> {matched}"
    )

print("PASS: All subscription filter tests")

