
package ca.lab.ocre;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "clinical_reports")
public class ClinicalReportEntity {

    @Id
    @Column(name = "id", nullable = false)
    private UUID id;

    @Column(
        name = "message_control_id",
        nullable = false,
        unique = true,
        length = 255
    )
    private String messageControlId;

    @Column(name = "mrn", nullable = false, length = 128)
    private String mrn;

    @Column(name = "patient_name", columnDefinition = "text")
    private String patientName;

    @Column(name = "physician_id", nullable = false, length = 128)
    private String physicianId;

    @Column(name = "report_code", nullable = false, length = 64)
    private String reportCode;

    @Column(name = "report_text", columnDefinition = "text")
    private String reportText;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "fhir_bundle", columnDefinition = "jsonb")
    private Map<String, Object> fhirBundle;

    @CreationTimestamp
    @Column(name = "received_at", nullable = false, updatable = false)
    private OffsetDateTime receivedAt;

    protected ClinicalReportEntity() {
        // Required by JPA
    }

    public ClinicalReportEntity(
            UUID id,
            String messageControlId,
            String mrn,
            String patientName,
            String physicianId,
            String reportCode,
            String reportText,
            Map<String, Object> fhirBundle) {

        this.id = id;
        this.messageControlId = messageControlId;
        this.mrn = mrn;
        this.patientName = patientName;
        this.physicianId = physicianId;
        this.reportCode = reportCode;
        this.reportText = reportText;
        this.fhirBundle = fhirBundle;
    }

    public UUID getId() {
        return id;
    }

    public String getMessageControlId() {
        return messageControlId;
    }

    public String getMrn() {
        return mrn;
    }

    public String getPatientName() {
        return patientName;
    }

    public String getPhysicianId() {
        return physicianId;
    }

    public String getReportCode() {
        return reportCode;
    }

    public String getReportText() {
        return reportText;
    }

    public Map<String, Object> getFhirBundle() {
        return fhirBundle;
    }

    public OffsetDateTime getReceivedAt() {
        return receivedAt;
    }
}

