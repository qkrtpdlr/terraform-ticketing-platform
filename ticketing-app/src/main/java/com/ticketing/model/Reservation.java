package com.ticketing.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "reservations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Reservation {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;
    
    @Column(name = "user_name", nullable = false)
    private String userName;
    
    @Column(nullable = false)
    private String email;
    
    @Column(nullable = false)
    private String phone;
    
    @Column(nullable = false)
    private Integer quantity;
    
    @Column(name = "total_price", nullable = false)
    private Integer totalPrice;
    
    @Column(nullable = false)
    private String status; // PENDING, CONFIRMED, CANCELLED
    
    @Column(name = "reservation_code", nullable = false, unique = true)
    private String reservationCode;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "confirmed_at")
    private LocalDateTime confirmedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (status == null) {
            status = "PENDING";
        }
        if (reservationCode == null) {
            reservationCode = generateReservationCode();
        }
    }
    
    private String generateReservationCode() {
        return "RSV-" + System.currentTimeMillis() + "-" + (int)(Math.random() * 9000 + 1000);
    }
}
