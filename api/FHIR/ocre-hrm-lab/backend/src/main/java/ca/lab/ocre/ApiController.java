package ca.lab.ocre;

import ca.uhn.fhir.context.FhirContext;
import ca.lab.ocre.Models.*;
import jakarta.validation.Valid;
import org.hl7.fhir.instance.model.api.IBaseResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import java.util.List;

@RestController
@RequestMapping("/api")
public class ApiController {
  private final ReportService reports;
  private final SubscriptionService subscriptions;
  private final FhirContext r4 = FhirContext.forR4();
  private final FhirContext dstu2 = FhirContext.forDstu2();

  public ApiController(ReportService reports, SubscriptionService subscriptions) {
    this.reports = reports; this.subscriptions = subscriptions;
  }

  @GetMapping("/status")
  public Object status() { return java.util.Map.of("service", "synthetic-ocre-lab", "status", "running"); }

  @PostMapping("/reports")
  public ReportSummary report(@Valid @RequestBody ReportInput input) throws Exception {
    return reports.accept(input);
  }

  @GetMapping("/reports")
  public List<ReportSummary> reports() { return reports.list(); }

  @GetMapping(value="/reports/{id}/fhir", produces="application/fhir+json")
  public ResponseEntity<String> reportFhir(@PathVariable String id) {
    String resource = reports.fhirBundle(id);
    if (resource == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Report not found");
    return ResponseEntity.ok().contentType(MediaType.parseMediaType("application/fhir+json")).body(resource);
  }

  @PostMapping("/subscriptions")
  public Preference subscribe(@Valid @RequestBody PreferenceInput input) {
    return subscriptions.subscribe(input);
  }

  @GetMapping("/subscriptions")
  public List<Preference> subscriptions() { return subscriptions.preferences(); }

  @GetMapping(value="/subscriptions/{id}/fhir", produces="application/fhir+json")
  public ResponseEntity<String> subscriptionFhir(@PathVariable String id) {
    return subscriptions.preferences().stream().filter(x -> x.id().equals(id)).findFirst()
        .map(x -> ResponseEntity.ok().contentType(MediaType.parseMediaType("application/fhir+json"))
            .body(x.fhirJson()))
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Subscription not found"));
  }

  @GetMapping("/deliveries")
  public List<Delivery> deliveries() { return subscriptions.deliveries(); }

  @PostMapping(value="/fhir/r4/parse", consumes={"application/fhir+json","application/json"})
  public ParseResult parseR4(@RequestBody String body) {
    return parse(r4, "R4", body);
  }

  @PostMapping(value="/fhir/dstu2/parse", consumes={"application/fhir+json","application/json"})
  public ParseResult parseDstu2(@RequestBody String body) {
    return parse(dstu2, "DSTU2", body);
  }


  @PostMapping(
      value = "/subscriptions/fhir",
      consumes = {
          "application/fhir+json",
          "application/json"
      }
  )
  public Preference subscribeFhir(@RequestBody String fhirJson) {
      try {
          return subscriptions.subscribeFhir(fhirJson);
      } catch ( IllegalArgumentException | ca.uhn.fhir.parser.DataFormatException ex) {
          throw new ResponseStatusException( HttpStatus.BAD_REQUEST, ex.getMessage());
      }
  }


  private ParseResult parse(FhirContext context, String version, String body) {
    try {
      IBaseResource resource = context.newJsonParser().parseResource(body);
      return new ParseResult(version, context.getResourceDefinition(resource).getName(),
          resource.getIdElement().getIdPart());
    } catch (Exception ex) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "FHIR parsing failed: " + ex.getMessage());
    }
  }
}
