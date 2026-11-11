
package ca.lab.ocre;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.NoSuchElementException;

@Service
@Profile("postgres")
public class SubscriptionActivationService {

    private final PhysicianSubscriptionRepository repository;

    public SubscriptionActivationService(
            PhysicianSubscriptionRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public PhysicianSubscriptionEntity activate(String id) {

        var entity = repository.findById(id)
            .orElseThrow(() -> new NoSuchElementException(
                "Subscription not found: " + id
            ));

        // An already-active subscription is safe to activate again.
        if ("active".equals(entity.getStatus())) {
            return entity;
        }

        if (!"requested".equals(entity.getStatus())) {
            throw new IllegalStateException(
                "Cannot activate from status: " + entity.getStatus()
            );
        }

        Map<String, Object> current = entity.getFhirResource();

        if (current == null ||
                !"Subscription".equals(current.get("resourceType")) ||
                !id.equals(current.get("id"))) {
            throw new IllegalStateException(
                "Stored FHIR Subscription is missing or inconsistent"
            );
        }

        // Update the stored FHIR JSON as well as the SQL status column.
        Map<String, Object> updated =
            new LinkedHashMap<>(current);

        updated.put("status", "active");

        entity.setStatus("active");
        entity.setFhirResource(updated);

        return repository.saveAndFlush(entity);
    }
}

