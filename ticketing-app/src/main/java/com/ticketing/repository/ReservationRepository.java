package com.ticketing.repository;

import com.ticketing.model.Reservation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ReservationRepository extends JpaRepository<Reservation, Long> {
    
    Optional<Reservation> findByReservationCode(String reservationCode);
    
    List<Reservation> findByEmail(String email);
    
    List<Reservation> findByEventId(Long eventId);
}
