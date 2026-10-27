package ca.lab.ocre;

import ca.uhn.fhir.context.FhirContext;
import ca.lab.ocre.Models.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.hl7.fhir.r4.model.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@Profile("postgres")
public class PostgresSubscriptionService implements SubscriptionOperations {
    private static final Logger log = LoggerFactory.getLogger(PostgresSubscriptionService.class);
    private static final String FILTER_URL =
        "http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-filter-criteria";
    private static final String CONTENT_URL =
        "http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-payload-content";
    // Standardize to the same topic and physician-id key used by the mapper.
    private static final String TOPIC =
        "https://example.org/fhir/SubscriptionTopic/clinical-report-available";

    private final FhirContext fhir = FhirContext.forR4();
    private final BackportSubscriptionMapper mapper = new BackportSubscriptionMapper();
    private final ObjectMapper json;
    private final PhysicianSubscriptionRepository subscriptions;
    private final ClinicalReportRepository reports;
    private final ReportDeliveryRepository deliveries;

    public PostgresSubscriptionService(ObjectMapper json,
                                        PhysicianSubscriptionRepository subscriptions,
                                        ClinicalReportRepository reports,
                                        ReportDeliveryRepository deliveries) {
        this.json = json;
        this.subscriptions = subscriptions;
        this.reports = reports;
        this.deliveries = deliveries;
    }

    @Override
    public Preference subscribe(PreferenceInput input) {
        String id = UUID.randomUUID().toString();
        Subscription subscription = new Subscription();
        subscription.setId(id);
        subscription.getMeta().addProfile(
            "http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-subscription");
        subscription.setStatus(Subscription.SubscriptionStatus.REQUESTED);
        subscription.setReason("Synthetic OCRE lab: physician preference demonstration");
        subscription.setCriteria(TOPIC);
        subscription.getCriteriaElement().addExtension(new Extension(FILTER_URL,
                new StringType("physician-id=" + input.physicianId())));
        subscription.getCriteriaElement().addExtension(new Extension(FILTER_URL,
                new StringType("report-code=" + input.reportCode())));
        subscription.getChannel().setType(Subscription.SubscriptionChannelType.RESTHOOK);
        subscription.getChannel().setEndpoint("https://example.invalid/simulated-notification");
        subscription.getChannel().setPayload("application/fhir+json");
        subscription.getChannel().getPayloadElement().addExtension(
                new Extension(CONTENT_URL, new CodeType("full-resource")));
        String encoded = fhir.newJsonParser().setPrettyPrint(true)
                .encodeResourceToString(subscription);
        return save(id, input.physicianId(), input.reportCode(), encoded, "requested");
    }

    @Override
    public Preference subscribeFhir(String fhirJson) {
        var routing = mapper.parse(fhirJson);
        Subscription parsed = (Subscription) fhir.newJsonParser().parseResource(fhirJson);
        if (!parsed.hasStatus()) {
            throw new IllegalArgumentException("FHIR Subscription.status is required");
        }
        String status = parsed.getStatus().toCode();
        return save(routing.subscriptionId(), routing.physicianId(),
                routing.reportCode(), fhirJson, status);
    }

    private Preference save(String id, String physicianId, String reportCode,
                             String fhirJson, String status) {
        if (subscriptions.existsById(id)) {
            throw new IllegalArgumentException("Subscription already exists: " + id);
        }
        Map<String, Object> resource;
        try {
            resource = json.readValue(fhirJson, new TypeReference<Map<String, Object>>() {});
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid FHIR Subscription JSON", ex);
        }
        var entity = new PhysicianSubscriptionEntity(id, physicianId, reportCode, status);
        entity.setFhirResource(resource);
        subscriptions.saveAndFlush(entity);
        return new Preference(id, physicianId, reportCode, fhirJson);
    }

    @Override
    public List<Preference> preferences() {
        return subscriptions.findAll().stream().map(this::preference).toList();
    }

    private Preference preference(PhysicianSubscriptionEntity entity) {
        String fhirJson;
        try { fhirJson = json.writeValueAsString(entity.getFhirResource()); }
        catch (Exception ex) { throw new IllegalStateException(ex); }
        return new Preference(entity.getId(), entity.getPhysicianId(),
                entity.getReportCode(), fhirJson);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Delivery> deliveries() {
        return deliveries.findAll().stream()
                .map(d -> new Delivery(d.getReport().getId().toString(),
                        d.getSubscription().getId(), d.getPhysicianId(),
                        d.getReportCode(), d.getDeliveredAt().toInstant()))
                .toList();
    }

    @RabbitListener(queues = BrokerConfig.QUEUE)
    @Transactional
    public void receive(String payload) throws Exception {
        ReportEvent event = json.readValue(payload, ReportEvent.class);
        var report = reports.findById(UUID.fromString(event.id()));
        if (report.isEmpty()) {
            // The producer persists first. Missing reports must be investigated;
            // do not generate delivery records with broken foreign keys.
            throw new IllegalStateException("Report not found for event " + event.id());
        }
        Map<String, PhysicianSubscriptionEntity> matched = new LinkedHashMap<>();
        for (var pref : subscriptions.findByPhysicianIdAndReportCode(
                event.physicianId(), event.reportCode())) {
            matched.put(pref.getId(), pref);
        }
        for (var pref : subscriptions.findByPhysicianIdAndReportCode(
                event.physicianId(), "*")) {
            matched.put(pref.getId(), pref);
        }
        for (var pref : matched.values()) {
            if (!deliveries.existsByReport_IdAndSubscription_Id(
                    report.get().getId(), pref.getId())) {
                deliveries.save(new ReportDeliveryEntity(report.get(), pref,
                        event.physicianId(), event.reportCode()));
            }
        }
        // Deliberately preserves the existing simulator's behavior:
        // 'requested' subscriptions are also matched. Enforce ACTIVE in Lab 04D.
        log.debug("Matched {} subscriptions for report {}", matched.size(), event.id());
    }
}
