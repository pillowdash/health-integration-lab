
package ca.lab.ocre;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ReportDeliveryRepository
        extends JpaRepository<ReportDeliveryEntity, Long> {

    List<ReportDeliveryEntity> findByReport_Id(
        UUID reportId
    );

    List<ReportDeliveryEntity> findBySubscription_Id(
        String subscriptionId
    );

    boolean existsByReport_IdAndSubscription_Id(
        UUID reportId,
        String subscriptionId
    );
}

