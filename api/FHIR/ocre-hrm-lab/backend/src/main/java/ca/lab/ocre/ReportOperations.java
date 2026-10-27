package ca.lab.ocre;

import ca.lab.ocre.Models.ReportInput;
import ca.lab.ocre.Models.ReportSummary;
import java.util.List;

public interface ReportOperations {
    ReportSummary accept(ReportInput input) throws Exception;
    List<ReportSummary> list();
    String fhirBundle(String id);
}
