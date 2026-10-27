# Lab 01 — Build the Mirth HL7 v2 → REST channel

Use your existing `mirth452` NextGen Connect 4.5.2 container. These instructions configure a NEW channel through the Administrator UI; no channel XML is claimed to be importable. Verify existing port mappings first.

## 1. Docker networking

In the lab project folder run:

```bash
docker network inspect integration-lab >/dev/null || docker network create integration-lab
docker compose up -d --build
docker network connect integration-lab mirth452
```

If the last command says `already exists`, the connection is already in place. Verify with `docker network inspect integration-lab`. The Mirth container must resolve `ocre-api` as a Docker DNS name. The Java API is on container port 8080, host port 18081.

## 2. New channel

In Mirth Administrator → Channels → New Channel:

- Name: `OCRE_LAB_ORU_TO_FHIR`
- Source Connector: TCP Listener, `port = 2575` **inside Mirth**, using MLLP framing (VT/FS/CR). Confirm the port is unused by other channels; if 2575 is occupied choose a different port and publish it in your Mirth Docker Compose.
- Source inbound data type: HL7 v2.x. Source outbound type: HL7 v2.x.
- Destination: HTTP Sender, method POST, URL `http://ocre-api:8080/api/reports`, Content-Type `application/json`.
- Destination outbound data type: Raw; set its Request Content / template to `${jsonReport}`. UI labels vary slightly with connector options and version.

## 3. Source Transformer → JavaScript Step

This script is for the exact synthetic ORU sample. It is **not** a production ORU parser; robust production mappings handle repeating PID-3, NTE segments, coded provider identifiers, OBX data types, and multiple OBR groups.

```javascript
var type = msg['MSH']['MSH.9']['MSH.9.1'].toString();
var event = msg['MSH']['MSH.9']['MSH.9.2'].toString();
if (type !== 'ORU' || event !== 'R01') {
    throw 'Lab channel only accepts ORU^R01';
}
var obr = msg['OBR'][0];
var obx = msg['OBX'][0];
if (obr.length() === 0 || obx.length() === 0) {
    throw 'Missing OBR or OBX segment';
}
var payload = {
    messageControlId: msg['MSH']['MSH.10']['MSH.10.1'].toString(),
    mrn: msg['PID']['PID.3'][0]['PID.3.1'].toString(),
    patientName: msg['PID']['PID.5'][0]['PID.5.2'].toString() + ' ' + msg['PID']['PID.5'][0]['PID.5.1'].toString(),
    physicianId: obr['OBR.16']['OBR.16.1'].toString(),
    reportCode: obr['OBR.4']['OBR.4.1'].toString(),
    reportText: obx['OBX.5']['OBX.5.1'].toString()
};
if (!payload.messageControlId || !payload.mrn || !payload.physicianId || !payload.reportText) {
    throw 'Missing required fields';
}
channelMap.put('jsonReport', JSON.stringify(payload));
logger.info('Synthetic OCRE message ' + payload.messageControlId + ' transformed');
```

If your version represents OBR/OBX with XMLList differently, use Mirth Message Browser to inspect the actual parsed XML. Start with this single-report pattern before adding repeating OBR groups.

## 4. Destination HTTP Sender

- Select `HTTP Sender` with the above URL.
- Set **POST** and `Content-Type: application/json`.
- Use `${jsonReport}` as the raw request body/template. DO NOT wrap the JSON in another JSON string.
- Set retry and destination queue appropriately for this training phase; study response codes `2xx`, `4xx`, `5xx` in Destination → Sent/Error views.
- For this first lab, Source **Auto-generate HL7 ACK** may return an ACK before all downstream processing succeeds, depending on channel configuration. It is NOT an end-to-end delivery guarantee. We will explicitly implement AA/AE/AR based on final processing outcomes in a later exercise.

## 5. Test through Mirth

Deploy the new channel. From the Ubuntu host:

```bash
python3 examples/send-mllp.py --port 2575
curl -s http://localhost:18081/api/reports
curl -s http://localhost:18081/api/deliveries
```

Before sending the HL7 report, create a physician subscription for `P100` and report code `18842-5` in the React UI at http://localhost:5173. A matching delivery should appear after Mirth forwards the report.

### Troubleshooting

- **Connection refused on 2575:** confirm the original Mirth Docker Compose publishes this port and the channel listener uses it; if not, update the host-to-container mapping.
- **HTTP Sender cannot resolve `ocre-api`:** ensure both containers are attached to `integration-lab`.
- **4xx from Spring:** inspect the raw request body; missing or blank JSON fields cause validation errors.
- **502/connection error:** verify `docker compose ps` and `docker compose logs -f ocre-api`.
- **ACK but no report:** check the HTTP destination's Sent/Error log; MLLP ACK may not reflect destination status.
- **Duplicate message:** same MSH-10 is deliberately idempotent *only until backend restart*.
