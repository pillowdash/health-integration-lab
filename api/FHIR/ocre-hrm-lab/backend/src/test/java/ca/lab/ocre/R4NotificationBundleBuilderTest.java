
package ca.lab.ocre;

import ca.uhn.fhir.context.FhirContext;
import org.hl7.fhir.r4.model.*;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.*;

class R4NotificationBundleBuilderTest {

    private static final FhirContext FHIR =
        FhirContext.forR4();

    private final R4NotificationBundleBuilder builder =
        new R4NotificationBundleBuilder();

    // Create a minimal synthetic clinical report Bundle.
    private String sampleReportBundle() {

        String patientUrl = "urn:uuid:11111111-1111-4111-8111-111111111111";
        String practitionerUrl = "urn:uuid:22222222-2222-4222-8222-222222222222";
        String documentUrl = "urn:uuid:33333333-3333-4333-8333-333333333333";

        Patient patient = new Patient();
        patient.setId("11111111-1111-4111-8111-111111111111");
        patient.addName().setText("ALICE EXAMPLE");

        Practitioner practitioner = new Practitioner();
        practitioner.setId("22222222-2222-4222-8222-222222222222");
        practitioner.addIdentifier().setValue("P100");

        DocumentReference document = new DocumentReference();
        document.setId("33333333-3333-4333-8333-333333333333");
        document.setStatus(Enumerations.DocumentReferenceStatus.CURRENT);
        document.setSubject(new Reference(patientUrl));
        document.addAuthor(new Reference(practitionerUrl));
        document.getType().addCoding()
            .setSystem("http://loinc.org")
            .setCode("18842-5");

        document.addContent().setAttachment(
            new Attachment()
                .setContentType("text/plain")
                .setData("Synthetic report".getBytes(
                    StandardCharsets.UTF_8))
        );

        Bundle source = new Bundle();
        source.setType(Bundle.BundleType.COLLECTION);

        source.addEntry()
            .setFullUrl(patientUrl)
            .setResource(patient);

        source.addEntry()
            .setFullUrl(practitionerUrl)
            .setResource(practitioner);

        source.addEntry()
            .setFullUrl(documentUrl)
            .setResource(document);

        return FHIR.newJsonParser()
            .encodeResourceToString(source);
    }

    @Test
    void createsValidNotificationStructure() {

        String json = builder.build(
            "physician-p100",
            "active",
            sampleReportBundle(),
            1
        );

        Bundle result = (Bundle)
            FHIR.newJsonParser().parseResource(json);

        assertEquals(Bundle.BundleType.HISTORY, result.getType());
        assertEquals(4, result.getEntry().size());

        // First entry must be Parameters in R4.
        assertInstanceOf(
            Parameters.class,
            result.getEntryFirstRep().getResource()
        );

        Parameters status = (Parameters)
            result.getEntryFirstRep().getResource();

        assertEquals(
            "active",
            status.getParameter().stream()
                .filter(p -> p.getName().equals("status"))
                .findFirst().orElseThrow()
                .getValue().primitiveValue()
        );

        assertEquals(
            "event-notification",
            status.getParameter().stream()
                .filter(p -> p.getName().equals("type"))
                .findFirst().orElseThrow()
                .getValue().primitiveValue()
        );

        var event = status.getParameter().stream()
            .filter(p -> p.getName().equals("notification-event"))
            .findFirst().orElseThrow();

        String focus = ((Reference) event.getPart().stream()
            .filter(p -> p.getName().equals("focus"))
            .findFirst().orElseThrow()
            .getValue()).getReference();

        // The focus refers to the embedded DocumentReference.
        assertTrue(result.getEntry().stream().anyMatch(
            e -> focus.equals(e.getFullUrl())
                && e.getResource() instanceof DocumentReference
        ));

        // History entries require request and response metadata.
        for (var entry : result.getEntry()) {
            assertTrue(entry.hasRequest());
            assertTrue(entry.hasResponse());
        }

        System.out.println(
            "FHIR R4 notification Bundle structure PASSED"
        );
    }

    @Test
    void requestedSubscriptionCannotGenerateEventNotification() {
        assertThrows(
            IllegalArgumentException.class,
            () -> builder.build(
                "physician-p100",
                "requested",
                sampleReportBundle(),
                1
            )
        );
    }

    @Test
    void eventNumberMustBePositive() {
        assertThrows(
            IllegalArgumentException.class,
            () -> builder.build(
                "physician-p100",
                "active",
                sampleReportBundle(),
                0
            )
        );
    }
}

