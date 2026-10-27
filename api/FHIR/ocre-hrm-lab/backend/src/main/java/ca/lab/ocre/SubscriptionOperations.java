package ca.lab.ocre;

import ca.lab.ocre.Models.Delivery;
import ca.lab.ocre.Models.Preference;
import ca.lab.ocre.Models.PreferenceInput;
import java.util.List;

public interface SubscriptionOperations {
    Preference subscribe(PreferenceInput input);
    Preference subscribeFhir(String fhirJson);
    List<Preference> preferences();
    List<Delivery> deliveries();
}
