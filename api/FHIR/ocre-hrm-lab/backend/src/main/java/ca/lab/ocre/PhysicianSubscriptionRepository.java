
package ca.lab.ocre;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface PhysicianSubscriptionRepository
        extends JpaRepository<PhysicianSubscriptionEntity, String> {

    List<PhysicianSubscriptionEntity>
        findByPhysicianIdAndReportCode(
            String physicianId,
            String reportCode
        );
}

