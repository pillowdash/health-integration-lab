package ca.lab.ocre;

import ca.lab.ocre.Models.ReportInput;
import ca.lab.ocre.Models.ReportSummary;
import ca.lab.ocre.Models.ReportEvent;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@Profile("postgres")
public class PostgresReportService implements ReportOperations {
    private final ClinicalReportRepository reports;
    private final RabbitTemplate broker;
    private final ObjectMapper json;

    public PostgresReportService(ClinicalReportRepository reports,
                                 RabbitTemplate broker, ObjectMapper json) {
        this.reports = reports;
        this.broker = broker;
        this.json = json;
    }

    @Override
    public ReportSummary accept(ReportInput input) throws Exception {
        // Persist before publishing. saveAndFlush() completes its own repository
        // transaction before the RabbitMQ publish because this method is NOT
        // @Transactional. This is not atomic; add an outbox in a later lab.
        var previous = reports.findByMessageControlId(input.messageControlId());
        ClinicalReportEntity entity;
        if (previous.isPresent()) {
            entity = previous.get();
        } else {
            String bundleJson = ClinicalReportFhirFactory.createBundle(input);
            Map<String, Object> bundle = json.readValue(bundleJson,
                    new TypeReference<Map<String, Object>>() {});
            entity = reports.saveAndFlush(new ClinicalReportEntity(
                    UUID.randomUUID(), input.messageControlId(), input.mrn(),
                    input.patientName(), input.physicianId(), input.reportCode(),
                    input.reportText(), bundle));
        }

        // Republish even on a duplicate request: this enables retry if a previous
        // DB commit succeeded but RabbitMQ publication failed. The consumer's
        // (report_id, subscription_id) uniqueness constraint prevents duplicate
        // delivery records. This is at-least-once, not an outbox guarantee.
        var event = new ReportEvent(entity.getId().toString(),
                entity.getPhysicianId(), entity.getReportCode());
        broker.convertAndSend(BrokerConfig.EXCHANGE,
                "report." + entity.getPhysicianId(), json.writeValueAsString(event));
        return summary(entity);
    }

    @Override
    public List<ReportSummary> list() {
        return reports.findAll().stream().map(this::summary)
                .sorted(Comparator.comparing(ReportSummary::receivedAt).reversed())
                .toList();
    }

    @Override
    public String fhirBundle(String id) {
        try {
            return reports.findById(UUID.fromString(id))
                    .map(ClinicalReportEntity::getFhirBundle)
                    .map(bundle -> {
                        try { return json.writeValueAsString(bundle); }
                        catch (Exception ex) { throw new IllegalStateException(ex); }
                    })
                    .orElse(null);
        } catch (IllegalArgumentException invalidUuid) {
            return null;
        }
    }

    private ReportSummary summary(ClinicalReportEntity entity) {
        return new ReportSummary(entity.getId().toString(),
                entity.getMessageControlId(), entity.getMrn(),
                entity.getPhysicianId(), entity.getReportCode(),
                entity.getReceivedAt().toInstant());
    }
}
