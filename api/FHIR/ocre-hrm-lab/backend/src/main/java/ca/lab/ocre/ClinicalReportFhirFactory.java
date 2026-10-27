package ca.lab.ocre;

import ca.uhn.fhir.context.FhirContext;
import ca.lab.ocre.Models.ReportInput;
import org.hl7.fhir.r4.model.*;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

// Matches the original ReportService FHIR Bundle construction logic.
final class ClinicalReportFhirFactory {
    private static final FhirContext FHIR = FhirContext.forR4();
    private ClinicalReportFhirFactory() {}

    static String createBundle(ReportInput input) {
        String patientId = UUID.randomUUID().toString();
        String patientUrl = "urn:uuid:" + patientId;
        String practitionerId = UUID.randomUUID().toString();
        String practitionerUrl = "urn:uuid:" + practitionerId;
        String documentId = UUID.randomUUID().toString();
        String documentUrl = "urn:uuid:" + documentId;

        Patient patient = new Patient();
        patient.setId(patientId);
        patient.addIdentifier().setSystem("https://example.org/synthetic-mrn")
                .setValue(input.mrn());
        patient.addName().setText(input.patientName());

        Practitioner practitioner = new Practitioner();
        practitioner.setId(practitionerId);
        practitioner.addIdentifier().setSystem("https://example.org/synthetic-physician-id")
                .setValue(input.physicianId());

        DocumentReference document = new DocumentReference();
        document.setId(documentId);
        document.setStatus(Enumerations.DocumentReferenceStatus.CURRENT);
        document.setDate(Date.from(Instant.now()));
        document.setSubject(new Reference(patientUrl));
        document.addAuthor(new Reference(practitionerUrl));
        document.getType().addCoding().setSystem("http://loinc.org")
                .setCode(input.reportCode());
        Attachment attachment = new Attachment();
        attachment.setContentType("text/plain")
                .setTitle("Synthetic clinical report")
                .setData(input.reportText().getBytes(StandardCharsets.UTF_8));
        document.addContent().setAttachment(attachment);

        Bundle bundle = new Bundle();
        bundle.setType(Bundle.BundleType.COLLECTION);
        bundle.addEntry().setFullUrl(patientUrl).setResource(patient);
        bundle.addEntry().setFullUrl(practitionerUrl).setResource(practitioner);
        bundle.addEntry().setFullUrl(documentUrl).setResource(document);
        return FHIR.newJsonParser().setPrettyPrint(true)
                .encodeResourceToString(bundle);
    }
}
