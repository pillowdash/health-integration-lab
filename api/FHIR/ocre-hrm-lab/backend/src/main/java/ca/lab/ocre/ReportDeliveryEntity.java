
package ca.lab.ocre;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;

@Entity
@Table(name = "report_deliveries")
public class ReportDeliveryEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "report_id", nullable = false)
    private ClinicalReportEntity report;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "subscription_id", nullable = false)
    private PhysicianSubscriptionEntity subscription;

    @Column(name = "physician_id", nullable = false, length = 128)
    private String physicianId;

    @Column(name = "report_code", nullable = false, length = 64)
    private String reportCode;

    @CreationTimestamp
    @Column(name = "delivered_at", nullable = false, updatable = false)
    private OffsetDateTime deliveredAt;

    protected ReportDeliveryEntity() {
        // Required by JPA
    }

    public ReportDeliveryEntity(
            ClinicalReportEntity report,
            PhysicianSubscriptionEntity subscription,
            String physicianId,
            String reportCode) {

        this.report = report;
        this.subscription = subscription;
        this.physicianId = physicianId;
        this.reportCode = reportCode;
    }

    public Long getId() {
        return id;
    }

    public ClinicalReportEntity getReport() {
        return report;
    }

    public PhysicianSubscriptionEntity getSubscription() {
        return subscription;
    }

    public String getPhysicianId() {
        return physicianId;
    }

    public String getReportCode() {
        return reportCode;
    }

    public OffsetDateTime getDeliveredAt() {
        return deliveredAt;
    }
}

