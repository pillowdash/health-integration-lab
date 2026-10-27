
package ca.lab.ocre;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

class FhirSubscriptionRegistrationTest {

    @Test
    void registeredFhirSubscriptionMatchesRabbitEvent()
            throws Exception {

        // Create a fresh service with empty in-memory lists
        var service = new SubscriptionService(
            new ObjectMapper()
        );

        // Load our FHIR Subscription example
        String json = Files.readString(Path.of(
            "../examples/lab04/subscription-p100.json"
        ));

        // Register through the new Java method
        var preference = service.subscribeFhir(json);

        assertEquals("P100", preference.physicianId());
        assertEquals("18842-5", preference.reportCode());
        assertEquals(1, service.preferences().size());

        // Report for a different physician: no match
        service.receive("""
            {
              "id": "report-p999",
              "physicianId": "P999",
              "reportCode": "18842-5"
            }
            """);

        assertEquals(0, service.deliveries().size());

        // Report for P100: should match
        service.receive("""
            {
              "id": "report-p100",
              "physicianId": "P100",
              "reportCode": "18842-5"
            }
            """);

        assertEquals(1, service.deliveries().size());

        var delivery = service.deliveries().get(0);

        assertEquals("report-p100", delivery.reportId());
        assertEquals(
            "physician-p100",
            delivery.subscriptionId()
        );
    }
}

