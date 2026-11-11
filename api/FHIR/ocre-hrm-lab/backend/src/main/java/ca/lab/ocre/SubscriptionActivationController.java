
package ca.lab.ocre;

import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;
import java.util.NoSuchElementException;

@RestController
@Profile("postgres")
@RequestMapping("/api/subscriptions")
public class SubscriptionActivationController {

    private final SubscriptionActivationService activation;

    public SubscriptionActivationController(
            SubscriptionActivationService activation) {
        this.activation = activation;
    }

    @PostMapping("/{id}/activate")
    public Map<String, String> activate(@PathVariable String id) {

        try {
            var entity = activation.activate(id);

            return Map.of(
                "id", entity.getId(),
                "physicianId", entity.getPhysicianId(),
                "reportCode", entity.getReportCode(),
                "status", entity.getStatus()
            );

        } catch (NoSuchElementException ex) {
            throw new ResponseStatusException(
                HttpStatus.NOT_FOUND, ex.getMessage()
            );

        } catch (IllegalStateException ex) {
            throw new ResponseStatusException(
                HttpStatus.CONFLICT, ex.getMessage()
            );
        }
    }
}

