package ca.lab.ocre;

import ca.lab.ocre.Models.PreferenceInput;
import com.fasterxml.jackson.databind.ObjectMapper;
import ca.uhn.fhir.context.FhirContext;
import org.hl7.fhir.r4.model.Subscription;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

class SubscriptionServiceTest {
  @Test void buildsR4BackportShapedSubscriptionAndMatchesPhysician() throws Exception {
    var service = new SubscriptionService(new ObjectMapper());
    var pref = service.subscribe(new PreferenceInput("P100", "18842-5"));
    var sub = (Subscription) FhirContext.forR4().newJsonParser().parseResource(pref.fhirJson());
    assertThat(sub.getCriteria()).contains("synthetic-clinical-report");
    assertThat(pref.fhirJson()).contains("backport-filter-criteria", "physician=P100");
    service.receive("{\"id\":\"report1\",\"physicianId\":\"P200\",\"reportCode\":\"18842-5\"}");
    assertThat(service.deliveries()).isEmpty();
    service.receive("{\"id\":\"report2\",\"physicianId\":\"P100\",\"reportCode\":\"18842-5\"}");
    assertThat(service.deliveries()).hasSize(1);
  }
}
