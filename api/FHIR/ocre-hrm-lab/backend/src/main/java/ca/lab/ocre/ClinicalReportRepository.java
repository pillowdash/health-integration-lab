
package ca.lab.ocre;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ClinicalReportRepository
        extends JpaRepository<ClinicalReportEntity, UUID> {

    Optional<ClinicalReportEntity>
        findByMessageControlId(String messageControlId);

    List<ClinicalReportEntity>
        findByPhysicianIdAndReportCode(
            String physicianId,
            String reportCode
        );
}

