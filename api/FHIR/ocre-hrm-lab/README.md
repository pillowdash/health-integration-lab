# Ontario OCRE / HRM Modernization — Practical Integration Lab

> Training simulator for **synthetic clinical data only**. This is not an Ontario Health product, production HRM implementation, or certified/conformant OCRE connector.

## What you get

A local demo implementation of two paths:

**Report path:** synthetic HL7 ORU → your existing Mirth TCP/MLLP channel → Spring Boot REST API → HAPI FHIR R4 Bundle (Patient, Practitioner, DocumentReference) → RabbitMQ event → physician preference matching.

**Subscription path:** React admin UI → Spring Boot → FHIR R4 Subscription with the R5-backport filter extensions → local preference store → simulate matching against report events.

**FHIR version practice:** an R4 endpoint and separate DSTU2 parser to observe version differences.

The local RabbitMQ broker is **not** Ontario Health Enterprise Pub/Sub. The FHIR profile references and topic/filter names are illustrative, not registered provincial topics. This project currently **parses and generates** FHIR resources but does not validate against licensed Ontario OCRE packages. It does not implement production OAuth 2.0, mTLS, actual REST-hook delivery, transactions/outbox, durable persistence, FHIR notification bundles or PHI logging/privacy controls.

## Requirements

- Ubuntu with Docker Engine and Docker Compose plugin.
- Existing Mirth 4.5.2 Docker container (`mirth452`), as previously configured in your healthcare integration lab.
- Internet access on **your machine** for first-time Docker image and Maven/NPM dependencies.
- Free ports `18081`, `5173`, `15672`, and a free Mirth TCP Listener port (sample: `2575`).

## First run

```bash
cd ocre-hrm-lab
docker network inspect integration-lab >/dev/null 2>&1 || docker network create integration-lab
docker compose up -d --build
docker compose ps
curl http://127.0.0.1:18081/api/status
```

Open:

- React console: http://localhost:5173
- Spring Boot API: http://localhost:18081/api/status
- RabbitMQ management: http://localhost:15672 (`labuser` / `labonly-change-me`; local lab only)
- Mirth Administrator: your existing Mirth Administrator address.

If image pulls fail or your network is offline, the application cannot build until dependencies are available. Existing Docker Compose projects sharing a network can coexist, but verify there are no port conflicts.

## Quick test WITHOUT Mirth (isolates Java/FHIR/PubSub)

In the React UI, add a subscription with physician `P100` and report code `18842-5`. Then run:

```bash
curl -sS -X POST http://127.0.0.1:18081/api/reports \
  -H 'Content-Type: application/json' \
  --data-binary @examples/report.json

curl -sS http://127.0.0.1:18081/api/reports
curl -sS http://127.0.0.1:18081/api/deliveries
```

The dashboard should show 1 report, 1 subscription and 1 simulated matching delivery. You can click **FHIR Bundle** and **FHIR JSON** to inspect HAPI-generated resources. If you rerun the same `examples/report.json`, the message control ID prevents re-publishing in this session. Restarting Spring loses in-memory state.

If a report is sent **before** the subscription was created, the simulator does not retroactively deliver it. Change messageControlId to a new value for another test.

## Then test WITH Mirth

Follow [docs/mirth-channel.md](docs/mirth-channel.md) to create the Mirth HTTP channel and send [examples/synthetic-oru.hl7](examples/synthetic-oru.hl7) over MLLP. The HL7 sample uses `SYNTH-OCRE-0002` so it won't conflict with the JSON test.

```bash
# Example: connect your existing Mirth container to the project network
# 'already exists' is fine; run only if not already connected.
docker network connect integration-lab mirth452
python3 examples/send-mllp.py --port 2575
```

## FHIR R4 versus DSTU2

Both endpoints use HAPI FHIR parsers, **not full profile validation**:

```bash
curl -sS -X POST http://localhost:18081/api/fhir/r4/parse \
  -H 'Content-Type: application/fhir+json' \
  -d '{"resourceType":"Patient","id":"r4-patient","name":[{"family":"Example"}]}'

curl -sS -X POST http://localhost:18081/api/fhir/dstu2/parse \
  -H 'Content-Type: application/fhir+json' \
  -d '{"resourceType":"Patient","id":"dstu2-patient","name":[{"family":["Example"]}]}'
```

## Tests (requires Docker; downloads test dependencies on first run)

```bash
docker run --rm -v "$PWD/backend:/work" -w /work maven:3.9-eclipse-temurin-21 mvn test
```

The first JUnit test checks R4 Bundle creation and MSH-10-equivalent idempotency. Later lessons should cover Mirth mapping tests, HL7 invalid messages, conformance, broker outages, security, retry/dead-letter/replay, OAuth 2.0 and mTLS.

## Honest engineering limitations

1. Data is held in process memory only and cleared on restart. RabbitMQ messages persist only as configured by queue durability, but no durable inbox/outbox exists. A broker publish can succeed before application state is committed.
2. The application uses HAPI FHIR R4 to build syntactically valid resources; generated documents do **not** claim Ontario OCRE conformance, and Subscription filter names (`physician`, `report-code`) are illustrative and depend on a fictitious topic.
3. The sample creates FHIR R4 Subscriptions using standard backport-extension URLs, but **does not** send them to Ontario Enterprise Pub/Sub or execute network REST-hook notifications.
4. The synthetic Mirth mapping only supports one ORU/OBR/OBX report. No true HRM HL7 v2 standard implementation or full ACK-after-downstream-confirmation is provided.
5. The API and RabbitMQ are development-only and are not secure for clinical information. All identifiers and clinical text **must be synthetic**.
6. A matching event is recorded after RabbitMQ consumption; it is **not** a confirmed EMR delivery and does not include retry/deduplication on the consumer side.
7. Complete tests require building with Docker; source has been packaged but may need environment-dependent adjustments.

## Suggested expansion lessons

- 02: Model an OCRE conformance-driven document bundle from the actual provincial profiles (acquire the standard package via Ontario Health).
- 03: Test HAPI DSTU2↔R4 mappings and implement parsing + structure validation using official packages.
- 04: Implement genuine SubscriptionTopic definition and topic-defined filter names; create R4 backport subscription validation.
- 05: Add broker dead-letter queues, retry, durable inbox/outbox, correlation IDs and message replay.
- 06: Add Keycloak OAuth 2.0 access tokens, role enforcement, API audit events, mTLS between Mirth and Spring.
- 07: Add React CRUD for physician preferences and role-based visibility.
- 08: Complete interface, conformance, regression and end-to-end tests; document what is simulated vs proven.

## Public source references

- Ontario Health OCRE IG: https://www.ontariohealth.ca/digital/standards/data/ocre
- OCRE downloads/information: https://ehealthontario.on.ca/en/standards/ontario-clinical-report-exchange-ocre-hl7-fhir-implementation-guide-v1.0.0-ballot
- Ontario Subscription IG: https://www.ontariohealth.ca/digital/standards/connectivity/ontario-subscription-hl7--fhir-
- HL7 Subscription Backport: https://www.hl7.org/fhir/uv/subscriptions-backport/
- HAPI FHIR: https://hapifhir.io/
- Mirth 4.5 user guide: https://downloads.mirthcorp.com/connect-user-guide/latest/mirth-connect-user-guide.pdf
