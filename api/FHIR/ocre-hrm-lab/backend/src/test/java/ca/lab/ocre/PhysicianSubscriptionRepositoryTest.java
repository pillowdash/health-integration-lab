
package ca.lab.ocre;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

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
class PhysicianSubscriptionRepositoryTest {

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
    private PhysicianSubscriptionRepository repository;

    @PersistenceContext
    private EntityManager entityManager;

    @Test
    void saveAndRetrievePhysicianSubscription() {

        String id = "jpa-test-" + UUID.randomUUID();

        var subscription = new PhysicianSubscriptionEntity(
            id,
            "P100",
            "18842-5",
            "requested"
        );

        // Hibernate generates an INSERT
        repository.saveAndFlush(subscription);

        // Clear the first-level cache to force a database read
        entityManager.clear();

        // Spring Data JPA retrieves the row
        var restored = repository.findById(id).orElseThrow();

        assertEquals("P100", restored.getPhysicianId());
        assertEquals("18842-5", restored.getReportCode());
        assertEquals("requested", restored.getStatus());

        assertNotNull(restored.getCreatedAt());
        assertNotNull(restored.getUpdatedAt());

        System.out.println("JPA PostgreSQL read/write test PASSED");
    }
}

