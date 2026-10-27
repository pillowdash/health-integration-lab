package ca.lab.ocre;

import ca.uhn.fhir.context.FhirContext;
import ca.lab.ocre.Models.ReportInput;
import ca.lab.ocre.Models.ReportSummary;
import ca.lab.ocre.Models.ReportEvent;
import org.hl7.fhir.r4.model.*;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;
import org.springframework.context.annotation.Profile;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
@Profile("!postgres")
public class ReportService implements ReportOperations {
  private final RabbitTemplate broker;
  private final ObjectMapper json;
  private final FhirContext fhir = FhirContext.forR4();
  private final Map<String, ReportSummary> reports = new ConcurrentHashMap<>();
  private final Map<String, String> fhirBundles = new ConcurrentHashMap<>();
  private final Map<String, String> controlIdToId = new ConcurrentHashMap<>();

  public ReportService(RabbitTemplate broker, ObjectMapper json) {
    this.broker = broker; this.json = json;
  }

  // In-memory idempotency for learning only. Real deployments require durable inbox/outbox and publisher confirms.
  public synchronized ReportSummary accept(ReportInput input) throws Exception {
    if (controlIdToId.containsKey(input.messageControlId())) {
      return reports.get(controlIdToId.get(input.messageControlId()));
    }
    String id = UUID.randomUUID().toString();
    String patientId = UUID.randomUUID().toString();
    String patientUrl = "urn:uuid:" + patientId;
    String practitionerId = UUID.randomUUID().toString();
    String practitionerUrl = "urn:uuid:" + practitionerId;
    String documentId = UUID.randomUUID().toString();
    String documentUrl = "urn:uuid:" + documentId;

    Patient patient = new Patient();
    patient.setId(patientId);
    patient.addIdentifier().setSystem("https://example.org/synthetic-mrn").setValue(input.mrn());
    // Display-only, synthetic name; don't assume incoming HL7 is normalized in a real project.
    patient.addName().setText(input.patientName());

    Practitioner practitioner = new Practitioner();
    practitioner.setId(practitionerId);
    practitioner.addIdentifier().setSystem("https://example.org/synthetic-physician-id")
        .setValue(input.physicianId());

    DocumentReference document = new DocumentReference();
    document.setId(documentId);
    //document.setStatus(DocumentReference.DocumentReferenceStatus.CURRENT);
    document.setStatus(Enumerations.DocumentReferenceStatus.CURRENT);
    document.setDate(Date.from(Instant.now()));
    document.setSubject(new Reference(patientUrl));
    document.addAuthor(new Reference(practitionerUrl));
    document.getType().addCoding().setSystem("http://loinc.org").setCode(input.reportCode());
    Attachment attachment = new Attachment();
    attachment.setContentType("text/plain").setTitle("Synthetic clinical report")
        .setData(input.reportText().getBytes(StandardCharsets.UTF_8));
    document.addContent().setAttachment(attachment);

    Bundle bundle = new Bundle();
    bundle.setType(Bundle.BundleType.COLLECTION);
    bundle.addEntry().setFullUrl(patientUrl).setResource(patient);
    bundle.addEntry().setFullUrl(practitionerUrl).setResource(practitioner);
    bundle.addEntry().setFullUrl(documentUrl).setResource(document);
    String encoded = fhir.newJsonParser().setPrettyPrint(true).encodeResourceToString(bundle);

    // Publish first, then expose as accepted (still NOT an atomic database+broker transaction).
    ReportEvent event = new ReportEvent(id, input.physicianId(), input.reportCode());
    broker.convertAndSend(BrokerConfig.EXCHANGE, "report." + input.physicianId(),
        json.writeValueAsString(event));
    ReportSummary summary = new ReportSummary(id, input.messageControlId(), input.mrn(),
        input.physicianId(), input.reportCode(), Instant.now());
    fhirBundles.put(id, encoded);
    reports.put(id, summary);
    controlIdToId.put(input.messageControlId(), id);
    return summary;
  }

  public List<ReportSummary> list() {
    return reports.values().stream().sorted(Comparator.comparing(ReportSummary::receivedAt).reversed()).toList();
  }
  public String fhirBundle(String id) { return fhirBundles.get(id); }
}
