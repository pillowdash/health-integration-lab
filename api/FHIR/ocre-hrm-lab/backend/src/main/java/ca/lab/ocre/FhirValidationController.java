
package ca.lab.ocre;

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.parser.DataFormatException;
import ca.uhn.fhir.validation.FhirValidator;
import ca.uhn.fhir.validation.ValidationResult;
import ca.uhn.fhir.context.support.DefaultProfileValidationSupport;

import org.hl7.fhir.common.hapi.validation.support.CommonCodeSystemsTerminologyService;
import org.hl7.fhir.common.hapi.validation.support.InMemoryTerminologyServerValidationSupport;
import org.hl7.fhir.common.hapi.validation.support.ValidationSupportChain;
import org.hl7.fhir.common.hapi.validation.validator.FhirInstanceValidator;
import org.hl7.fhir.r4.model.OperationOutcome;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/fhir/r4")
public class FhirValidationController {

    private final FhirContext context;
    private final FhirValidator validator;

    public FhirValidationController() {

        // 1. Create the FHIR R4 context once
        context = FhirContext.forR4();

        // 2. Configure base validation definitions
        ValidationSupportChain support =
            new ValidationSupportChain(
                new DefaultProfileValidationSupport(context),
                new CommonCodeSystemsTerminologyService(context),
                new InMemoryTerminologyServerValidationSupport(context)
            );

        // 3. Create the instance validation module
        FhirInstanceValidator instanceValidator =
            new FhirInstanceValidator(support);

        // 4. Register the module
        validator = context.newValidator();
        validator.registerValidatorModule(instanceValidator);
    }

    @PostMapping(
        path = "/validate",
        consumes = {"application/json", "application/fhir+json"},
        produces = "application/fhir+json"
    )
    public ResponseEntity<String> validate(
        @RequestBody String fhirJson
    ) {
        try {
            // Validate the submitted FHIR JSON
            ValidationResult result =
                validator.validateWithResult(fhirJson);

            // Convert validation findings to FHIR OperationOutcome
            OperationOutcome outcome =
                (OperationOutcome) result.toOperationOutcome();

            String response = context.newJsonParser()
                .setPrettyPrint(true)
                .encodeResourceToString(outcome);

            // Validation completed, even if issues were detected
            return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(
                    "application/fhir+json"))
                .body(response);

        } catch (DataFormatException ex) {

            // Report malformed/unparseable FHIR input
            OperationOutcome outcome = new OperationOutcome();

            outcome.addIssue()
                .setSeverity(OperationOutcome.IssueSeverity.ERROR)
                .setCode(OperationOutcome.IssueType.INVALID)
                .setDiagnostics("Invalid FHIR input: " + ex.getMessage());

            String response = context.newJsonParser()
                .encodeResourceToString(outcome);

            return ResponseEntity.badRequest()
                .contentType(MediaType.parseMediaType(
                    "application/fhir+json"))
                .body(response);
        }
    }
}

