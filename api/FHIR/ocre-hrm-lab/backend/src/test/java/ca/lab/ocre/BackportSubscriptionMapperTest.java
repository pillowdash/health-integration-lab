
package ca.lab.ocre;

import org.junit.jupiter.api.Test;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

class BackportSubscriptionMapperTest {

    private final BackportSubscriptionMapper mapper =
        new BackportSubscriptionMapper();

    private String sample(String physician) throws Exception {
        return Files.readString(Path.of(
            "../examples/lab04/subscription-" + physician + ".json"
        ));
    }

    @Test
    void p100SubscriptionMatchesCorrectReport() throws Exception {

        var preference = mapper.parse(sample("p100"));

        assertEquals("physician-p100", preference.subscriptionId());
        assertEquals("P100", preference.physicianId());
        assertEquals("18842-5", preference.reportCode());

        assertTrue(preference.matches("P100", "18842-5"));
        assertFalse(preference.matches("P999", "18842-5"));
        assertFalse(preference.matches("P100", "99999-1"));
    }

    @Test
    void p999SubscriptionMatchesCorrectReport() throws Exception {

        var preference = mapper.parse(sample("p999"));

        assertEquals("physician-p999", preference.subscriptionId());
        assertTrue(preference.matches("P999", "18842-5"));
        assertFalse(preference.matches("P100", "18842-5"));
    }

    @Test
    void unknownFilterIsRejected() throws Exception {

        String json = sample("p100")
            .replace("physician-id=P100", "unknown-id=P100");

        assertThrows(
            IllegalArgumentException.class,
            () -> mapper.parse(json)
        );
    }

    @Test
    void emptyReportCodeIsRejected() throws Exception {

        String json = sample("p100")
            .replace("report-code=18842-5", "report-code=");

        assertThrows(
            IllegalArgumentException.class,
            () -> mapper.parse(json)
        );
    }

    @Test
    void wrongTopicIsRejected() throws Exception {

        String json = sample("p100")
            .replace(
                "clinical-report-available",
                "unsupported-topic"
            );

        assertThrows(
            IllegalArgumentException.class,
            () -> mapper.parse(json)
        );
    }
}

