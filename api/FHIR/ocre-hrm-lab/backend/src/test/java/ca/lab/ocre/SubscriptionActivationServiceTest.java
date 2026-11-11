
package ca.lab.ocre;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
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
@ActiveProfiles("postgres")
@Import(SubscriptionActivationService.class)
class SubscriptionActivationServiceTest {

    @DynamicPropertySource
    static void databasePassword(DynamicPropertyRegistry registry) {
        String password = System.getenv("OCRE_DB_PASSWORD");
        if (password == null || password.isBlank()) {
            throw new IllegalStateException(
                "OCRE_DB_PASSWORD is not configured");
        }
        registry.add("spring.datasource.password", () -> password);
    }

    @Autowired
    private PhysicianSubscriptionRepository repository;

    @Autowired
    private SubscriptionActivationService activation;

    @PersistenceContext
    private EntityManager entityManager;

    @Test
    void requestedSubscriptionBecomesActive() {

        String id = "jpa-activation-" + UUID.randomUUID();

        var entity = new PhysicianSubscriptionEntity(
            id, "P100", "18842-5", "requested"
        );

        entity.setFhirResource(Map.of(
            "resourceType", "Subscription",
            "id", id,
            "status", "requested"
        ));

        repository.saveAndFlush(entity);

        // Activate through our service.
        activation.activate(id);

        // Force PostgreSQL reload.
        entityManager.flush();
        entityManager.clear();

        var restored = repository.findById(id).orElseThrow();

        assertEquals("active", restored.getStatus());
        assertEquals(
            "active",
            restored.getFhirResource().get("status")
        );
        assertNotNull(restored.getUpdatedAt());

        // Activating twice should be harmless.
        activation.activate(id);

        System.out.println("FHIR subscription activation PASSED");
    }

    @Test
    void offSubscriptionCannotBeActivated() {

        String id = "jpa-off-" + UUID.randomUUID();

        var entity = new PhysicianSubscriptionEntity(
            id, "P999", "18842-5", "off"
        );

        entity.setFhirResource(Map.of(
            "resourceType", "Subscription",
            "id", id,
            "status", "off"
        ));

        repository.saveAndFlush(entity);

        assertThrows(
            IllegalStateException.class,
            () -> activation.activate(id)
        );
    }
}

