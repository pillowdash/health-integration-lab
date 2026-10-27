
package ca.lab.ocre;

import ca.uhn.fhir.context.FhirContext;
import org.hl7.fhir.r4.model.Extension;
import org.hl7.fhir.r4.model.StringType;
import org.hl7.fhir.r4.model.Subscription;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

public final class BackportSubscriptionMapper {

    private static final String TOPIC =
        "https://example.org/fhir/SubscriptionTopic/clinical-report-available";

    private static final String FILTER_URL =
        "http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-filter-criteria";

    private static final Set<String> ALLOWED_FILTERS =
        Set.of("physician-id", "report-code");

    private final FhirContext context = FhirContext.forR4();

    public RoutingPreference parse(String json) {

        var resource = context.newJsonParser().parseResource(json);

        if (!(resource instanceof Subscription sub)) {
            throw new IllegalArgumentException(
                "Expected an R4 Subscription resource"
            );
        }

        if (!TOPIC.equals(sub.getCriteria())) {
            throw new IllegalArgumentException(
                "Unsupported SubscriptionTopic: " + sub.getCriteria()
            );
        }

        Map<String, String> filters = new HashMap<>();

        for (Extension ext : sub.getCriteriaElement().getExtension()) {

            if (!FILTER_URL.equals(ext.getUrl())) {
                throw new IllegalArgumentException(
                    "Unsupported criteria extension: " + ext.getUrl()
                );
            }

            if (!(ext.getValue() instanceof StringType value)) {
                throw new IllegalArgumentException(
                    "Filter extension must contain valueString"
                );
            }

            String[] parts = value.getValue().split("=", 2);

            if (parts.length != 2 ||
                !ALLOWED_FILTERS.contains(parts[0]) ||
                parts[1].isBlank()) {
                throw new IllegalArgumentException(
                    "Invalid filter: " + value.getValue()
                );
            }

            if (filters.putIfAbsent(parts[0], parts[1]) != null) {
                throw new IllegalArgumentException(
                    "Duplicate filter: " + parts[0]
                );
            }
        }

        String physician = filters.get("physician-id");
        String reportCode = filters.get("report-code");

        if (physician == null || reportCode == null) {
            throw new IllegalArgumentException(
                "Both physician-id and report-code are required"
            );
        }

        String id = sub.getIdElement().getIdPart();

        if (id == null || id.isBlank()) {
            throw new IllegalArgumentException(
                "Subscription id is required for this lab"
            );
        }

        return new RoutingPreference(id, physician, reportCode);
    }

    public record RoutingPreference(
        String subscriptionId,
        String physicianId,
        String reportCode
    ) {
        public boolean matches(String physician, String code) {
            return physicianId.equals(physician)
                && reportCode.equals(code);
        }
    }
}

