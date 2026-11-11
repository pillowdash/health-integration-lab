
package ca.lab.ocre;

import ca.uhn.fhir.context.FhirContext;
import org.hl7.fhir.r4.model.*;

import java.time.Instant;
import java.util.Date;
import java.util.List;
import java.util.UUID;

public class R4NotificationBundleBuilder {

    private static final FhirContext FHIR = FhirContext.forR4();

    private static final String TOPIC =
        "https://example.org/fhir/SubscriptionTopic/clinical-report-available";

    private static final String STATUS_PROFILE =
        "http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-subscription-status-r4";

    private static final String BUNDLE_PROFILE =
        "http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-subscription-notification-r4";

    public String build(
            String subscriptionId,
            String subscriptionStatus,
            String reportBundleJson,
            long eventNumber) {

        if (subscriptionId == null ||
                !subscriptionId.matches("[A-Za-z0-9.-]{1,64}")) {
            throw new IllegalArgumentException(
                "A valid FHIR Subscription ID is required");
        }

        if (!"active".equals(subscriptionStatus)) {
            throw new IllegalArgumentException(
                "Subscription must be active");
        }

        if (eventNumber < 1) {
            throw new IllegalArgumentException(
                "Event number must be positive");
        }

        Resource parsed = (Resource)
            FHIR.newJsonParser().parseResource(reportBundleJson);

        if (!(parsed instanceof Bundle source) ||
                source.getType() != Bundle.BundleType.COLLECTION) {
            throw new IllegalArgumentException(
                "Expected the stored clinical report collection Bundle");
        }

        List<Bundle.BundleEntryComponent> documents =
            source.getEntry().stream()
                .filter(e -> e.getResource() instanceof DocumentReference)
                .toList();

        if (documents.size() != 1) {
            throw new IllegalArgumentException(
                "Expected exactly one DocumentReference");
        }

        String focusUrl = documents.get(0).getFullUrl();
        if (focusUrl == null || focusUrl.isBlank()) {
            throw new IllegalArgumentException(
                "DocumentReference must have a fullUrl");
        }

        Instant now = Instant.now();

        // In R4, the SubscriptionStatus information is
        // represented by a Parameters resource.
        Parameters status = new Parameters();
        status.getMeta().addProfile(STATUS_PROFILE);

        status.addParameter()
            .setName("subscription")
            .setValue(new Reference(
                "Subscription/" + subscriptionId));

        status.addParameter()
            .setName("status")
            .setValue(new CodeType("active"));

        status.addParameter()
            .setName("type")
            .setValue(new CodeType("event-notification"));

        status.addParameter()
            .setName("topic")
            .setValue(new CanonicalType(TOPIC));

        status.addParameter()
            .setName("events-since-subscription-start")
            .setValue(new StringType(Long.toString(eventNumber)));

        Parameters.ParametersParameterComponent event =
            status.addParameter().setName("notification-event");

        event.addPart()
            .setName("event-number")
            .setValue(new StringType(Long.toString(eventNumber)));

        event.addPart()
            .setName("timestamp")
            .setValue(new InstantType(Date.from(now)));

        event.addPart()
            .setName("focus")
            .setValue(new Reference(focusUrl));

        // Construct the R4 notification history Bundle.
        Bundle notification = new Bundle();
        notification.setType(Bundle.BundleType.HISTORY);
        notification.setTimestamp(Date.from(now));
        notification.getMeta().addProfile(BUNDLE_PROFILE);

        // First entry MUST be the Parameters status resource.
        Bundle.BundleEntryComponent statusEntry =
            notification.addEntry();

        statusEntry
            .setFullUrl("urn:uuid:" + UUID.randomUUID())
            .setResource(status);

        statusEntry.getRequest()
            .setMethod(Bundle.HTTPVerb.GET)
            .setUrl("Subscription/" + subscriptionId + "/$status");

        statusEntry.getResponse().setStatus("200 OK");

        // Full-resource payload: copy the original FHIR
        // Patient, Practitioner and DocumentReference entries.
        for (Bundle.BundleEntryComponent original :
                source.getEntry()) {

            Resource resource = original.getResource();

            if (resource == null ||
                    !original.hasFullUrl() ||
                    !resource.getIdElement().hasIdPart()) {
                throw new IllegalArgumentException(
                    "Stored FHIR Bundle contains an incomplete entry");
            }

            Bundle.BundleEntryComponent entry =
                notification.addEntry();

            entry.setFullUrl(original.getFullUrl());
            entry.setResource(resource);

            entry.getRequest()
                .setMethod(Bundle.HTTPVerb.GET)
                .setUrl(resource.fhirType() + "/" +
                    resource.getIdElement().getIdPart());

            entry.getResponse().setStatus("200 OK");
        }

        return FHIR.newJsonParser()
            .setPrettyPrint(true)
            .encodeResourceToString(notification);
    }
}

