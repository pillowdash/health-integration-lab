package ca.lab.ocre;

import ca.uhn.fhir.context.FhirContext;
import ca.lab.ocre.Models.*;
import org.hl7.fhir.r4.model.*;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
public class SubscriptionService {
  private static final String FILTER_URL =
      "http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-filter-criteria";
  private static final String CONTENT_URL =
      "http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-payload-content";
  private static final String TOPIC = "https://example.org/fhir/SubscriptionTopic/synthetic-clinical-report";
  private final FhirContext fhir = FhirContext.forR4();
  private final ObjectMapper json;
  private final List<Preference> preferences = new CopyOnWriteArrayList<>();
  private final List<Delivery> deliveries = new CopyOnWriteArrayList<>();
  private final BackportSubscriptionMapper mapper = new BackportSubscriptionMapper();

  public SubscriptionService(ObjectMapper json) { this.json = json; }

  public Preference subscribe(PreferenceInput input) {
    String id = UUID.randomUUID().toString();
    Subscription subscription = new Subscription();
    subscription.setId(id);
    subscription.getMeta().addProfile(
        "http://hl7.org/fhir/uv/subscriptions-backport/StructureDefinition/backport-subscription");
    subscription.setStatus(Subscription.SubscriptionStatus.REQUESTED);
    subscription.setReason("Synthetic OCRE lab: physician preference demonstration");
    subscription.setCriteria(TOPIC);
    subscription.getCriteriaElement().addExtension(new Extension(FILTER_URL,
        new StringType("physician=" + input.physicianId())));
    subscription.getCriteriaElement().addExtension(new Extension(FILTER_URL,
        new StringType("report-code=" + input.reportCode())));
    subscription.getChannel().setType(Subscription.SubscriptionChannelType.RESTHOOK);
    subscription.getChannel().setEndpoint("https://example.invalid/simulated-notification");
    subscription.getChannel().setPayload("application/fhir+json");
    subscription.getChannel().getPayloadElement().addExtension(
        new Extension(CONTENT_URL, new CodeType("full-resource")));
    String encoded = fhir.newJsonParser().setPrettyPrint(true).encodeResourceToString(subscription);
    Preference item = new Preference(id, input.physicianId(), input.reportCode(), encoded);
    preferences.add(item);
    return item;
  }



  public Preference subscribeFhir(String fhirJson) {
  
      // Parse FHIR Subscription into our routing model
      var routing = mapper.parse(fhirJson);

      // Avoid registering the same FHIR Subscription ID twice
      boolean exists = preferences.stream()
          .anyMatch(p -> p.id().equals(routing.subscriptionId()));

      if (exists) {
          throw new IllegalArgumentException(
              "Subscription already exists: " +
              routing.subscriptionId()
          );
      }

      // Convert the routing model to the existing Preference
      Preference preference = new Preference(
          routing.subscriptionId(),
          routing.physicianId(),
          routing.reportCode(),
          fhirJson
      );

      preferences.add(preference);

      return preference;
  }


  public List<Preference> preferences() { return List.copyOf(preferences); }
  public List<Delivery> deliveries() { return List.copyOf(deliveries); }

  @RabbitListener(queues = BrokerConfig.QUEUE)
  public void receive(String payload) throws Exception {
    ReportEvent event = json.readValue(payload, ReportEvent.class);
    for (Preference pref : preferences) {
      if (pref.physicianId().equals(event.physicianId()) &&
          (pref.reportCode().equals("*") || pref.reportCode().equals(event.reportCode()))) {
        Delivery delivery = new Delivery(event.id(), pref.id(), pref.physicianId(),
            event.reportCode(), Instant.now());
        // This records a simulated match, NOT an actual FHIR notification or EMR delivery.
        deliveries.add(delivery);
      }
    }
  }
}
