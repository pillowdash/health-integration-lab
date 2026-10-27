
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
class ClinicalReportRepositoryTest {

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
    private ClinicalReportRepository repository;

    @PersistenceContext
    private EntityManager entityManager;

    @Test
    void saveAndRetrieveClinicalReport() {

        UUID reportId = UUID.randomUUID();
        String messageId = "JPA-REPORT-" + UUID.randomUUID();

        // Synthetic minimal FHIR R4 Bundle
        Map<String, Object> fhirBundle = Map.of(
            "resourceType", "Bundle",
            "type", "collection"
        );

        var report = new ClinicalReportEntity(
            reportId,
            messageId,
            "TEST123",
            "ALICE EXAMPLE",
            "P100",
            "18842-5",
            "Synthetic discharge summary for lab.",
            fhirBundle
        );

        // INSERT into PostgreSQL
        repository.saveAndFlush(report);

        // Force the next lookup to read from PostgreSQL
        entityManager.clear();

        // Retrieve report by HL7 MSH-10
        var restored = repository
            .findByMessageControlId(messageId)
            .orElseThrow();

        assertEquals(reportId, restored.getId());
        assertEquals("TEST123", restored.getMrn());
        assertEquals("P100", restored.getPhysicianId());
        assertEquals("18842-5", restored.getReportCode());

        // Verify that JSONB survived the round trip
        assertNotNull(restored.getFhirBundle());
        assertEquals(
            "Bundle",
            restored.getFhirBundle().get("resourceType")
        );

        assertEquals(
            "collection",
            restored.getFhirBundle().get("type")
        );

        assertNotNull(restored.getReceivedAt());

        System.out.println(
            "Clinical report + FHIR JSONB persistence PASSED"
        );
    }
}

