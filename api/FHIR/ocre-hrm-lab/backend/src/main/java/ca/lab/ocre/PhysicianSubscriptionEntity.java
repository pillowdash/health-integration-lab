
package ca.lab.ocre;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;
import java.util.Map;

@Entity
@Table(name = "physician_subscriptions")
public class PhysicianSubscriptionEntity {

    @Id
    @Column(name = "id", length = 128)
    private String id;

    @Column(name = "physician_id", nullable = false)
    private String physicianId;

    @Column(name = "report_code", nullable = false)
    private String reportCode;

    @Column(name = "status", nullable = false)
    private String status;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "fhir_resource", columnDefinition = "jsonb")
    private Map<String, Object> fhirResource;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private OffsetDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    protected PhysicianSubscriptionEntity() {
        // Required by JPA
    }

    public PhysicianSubscriptionEntity(
            String id,
            String physicianId,
            String reportCode,
            String status) {

        this.id = id;
        this.physicianId = physicianId;
        this.reportCode = reportCode;
        this.status = status;
    }

    public String getId() {
        return id;
    }

    public String getPhysicianId() {
        return physicianId;
    }

    public String getReportCode() {
        return reportCode;
    }

    public String getStatus() {
        return status;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public Map<String, Object> getFhirResource() {
        return fhirResource;
    }

    public void setFhirResource(Map<String, Object> resource) {
        this.fhirResource = resource;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}

