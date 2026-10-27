
package ca.lab.ocre;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@DataJpaTest(properties = {
    "spring.datasource.url=jdbc:postgresql://ocre-postgres:5432/ocre_lab",
    "spring.datasource.username=ocre_lab",
    "spring.jpa.hibernate.ddl-auto=validate",
    "spring.flyway.enabled=false"
})
@AutoConfigureTestDatabase(
    replace = AutoConfigureTestDatabase.Replace.NONE
)
class ReportDeliveryRepositoryTest {

    @DynamicPropertySource
    static void databasePassword(DynamicPropertyRegistry registry) {
        String password = System.getenv("OCRE_DB_PASSWORD");

        if (password == null || password.isBlank()) {
            throw new IllegalStateException(
                "OCRE_DB_PASSWORD is not configured"
            );
        }

        registry.add("spring.datasource.password", () -> password);
    }

    @Autowired
    private ClinicalReportRepository reportRepository;

    @Autowired
    private PhysicianSubscriptionRepository subscriptionRepository;

    @Autowired
    private ReportDeliveryRepository deliveryRepository;

    @PersistenceContext
    private EntityManager entityManager;

    @Test
    void saveAndRetrieveReportDelivery() {

        UUID reportId = UUID.randomUUID();
        String messageId = "JPA-DELIVERY-" + UUID.randomUUID();
        String subscriptionId = "jpa-sub-" + UUID.randomUUID();

        // 1. Create the clinical report
        var report = new ClinicalReportEntity(
            reportId,
            messageId,
            "TEST123",
            "ALICE EXAMPLE",
            "P100",
            "18842-5",
            "Synthetic discharge summary.",
            Map.of(
                "resourceType", "Bundle",
                "type", "collection"
            )
        );

        reportRepository.saveAndFlush(report);

        // 2. Create the matching physician subscription
        var subscription = new PhysicianSubscriptionEntity(
            subscriptionId,
            "P100",
            "18842-5",
            "active"
        );

        subscriptionRepository.saveAndFlush(subscription);

        // 3. Create a delivery linking those two records
        var delivery = new ReportDeliveryEntity(
            report,
            subscription,
            "P100",
            "18842-5"
        );

        deliveryRepository.saveAndFlush(delivery);

        Long deliveryId = delivery.getId();
        assertNotNull(deliveryId);

        // 4. Clear Hibernate's first-level cache
        entityManager.clear();

        // 5. Reload the delivery from PostgreSQL
        var restored = deliveryRepository
            .findById(deliveryId)
            .orElseThrow();

        assertEquals("P100", restored.getPhysicianId());
        assertEquals("18842-5", restored.getReportCode());

        // 6. Verify relationships to both parent records
        assertEquals(
            messageId,
            restored.getReport().getMessageControlId()
        );

        assertEquals(
            subscriptionId,
            restored.getSubscription().getId()
        );

        assertNotNull(restored.getDeliveredAt());

        // 7. Verify repository relationship queries
        assertEquals(
            1,
            deliveryRepository.findByReport_Id(reportId).size()
        );

        assertTrue(
            deliveryRepository.existsByReport_IdAndSubscription_Id(
                reportId,
                subscriptionId
            )
        );

        System.out.println(
            "Report delivery + JPA relationships PASSED"
        );
    }
}
