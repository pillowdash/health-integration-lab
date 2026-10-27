package ca.lab.ocre;

import ca.lab.ocre.Models.ReportInput;
import com.fasterxml.jackson.databind.ObjectMapper;
import ca.uhn.fhir.context.FhirContext;
import org.hl7.fhir.r4.model.Bundle;
import org.junit.jupiter.api.Test;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

public class ReportServiceTest {
  @Test void createsFhirR4BundleAndDeduplicatesControlId() throws Exception {
    RabbitTemplate broker = mock(RabbitTemplate.class);
    ReportService service = new ReportService(broker, new ObjectMapper());
    ReportInput input = new ReportInput("MSG-1", "TEST123", "Alice Example", "P100",
        "18842-5", "Synthetic test report");
    var first = service.accept(input);
    var second = service.accept(input);
    assertThat(first.id()).isEqualTo(second.id());
    var bundle = (Bundle) FhirContext.forR4().newJsonParser()
        .parseResource(service.fhirBundle(first.id()));
    assertThat(bundle.getEntry()).hasSize(3);
    verify(broker, times(1)).convertAndSend(anyString(), anyString(), anyString());
  }
}
