package ca.lab.ocre;

import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

public final class Models {
  private Models() {}

  public record ReportInput(
      @NotBlank String messageControlId,
      @NotBlank String mrn,
      @NotBlank String patientName,
      @NotBlank String physicianId,
      @NotBlank String reportCode,
      @NotBlank String reportText) {}

  public record ReportSummary(String id, String messageControlId, String mrn,
                              String physicianId, String reportCode, Instant receivedAt) {}
  public record ReportEvent(String id, String physicianId, String reportCode) {}
  public record PreferenceInput(@NotBlank String physicianId, @NotBlank String reportCode) {}
  public record Preference(String id, String physicianId, String reportCode, String fhirJson) {}
  public record Delivery(String reportId, String subscriptionId, String physicianId,
                         String reportCode, Instant deliveredAt) {}
  public record ParseResult(String fhirVersion, String resourceType, String id) {}
}
