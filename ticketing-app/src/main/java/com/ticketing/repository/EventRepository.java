package com.ticketing.repository;

import com.ticketing.model.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EventRepository extends JpaRepository<Event, Long> {
    
    List<Event> findByStatus(String status);
    
    @Query("SELECT e FROM Event e WHERE e.status = 'AVAILABLE' AND e.availableSeats > 0 ORDER BY e.eventDate")
    List<Event> findAvailableEvents();
}
