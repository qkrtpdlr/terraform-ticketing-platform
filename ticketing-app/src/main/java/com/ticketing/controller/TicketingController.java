package com.ticketing.controller;

import com.ticketing.dto.ApiResponse;
import com.ticketing.dto.ReservationRequest;
import com.ticketing.model.Event;
import com.ticketing.model.Reservation;
import com.ticketing.service.TicketingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class TicketingController {
    
    private final TicketingService ticketingService;
    
    /**
     * Health Check
     */
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<String>> health() {
        return ResponseEntity.ok(ApiResponse.success("OK", "Ticketing Platform is running"));
    }
    
    /**
     * 모든 이벤트 조회
     */
    @GetMapping("/events")
    public ResponseEntity<ApiResponse<List<Event>>> getAllEvents() {
        log.info("GET /api/v1/events - 모든 이벤트 조회");
        List<Event> events = ticketingService.getAllEvents();
        return ResponseEntity.ok(ApiResponse.success("이벤트 목록을 조회했습니다", events));
    }
    
    /**
     * 예매 가능한 이벤트 조회
     */
    @GetMapping("/events/available")
    public ResponseEntity<ApiResponse<List<Event>>> getAvailableEvents() {
        log.info("GET /api/v1/events/available - 예매 가능한 이벤트 조회");
        List<Event> events = ticketingService.getAvailableEvents();
        return ResponseEntity.ok(ApiResponse.success("예매 가능한 이벤트를 조회했습니다", events));
    }
    
    /**
     * 이벤트 상세 조회
     */
    @GetMapping("/events/{eventId}")
    public ResponseEntity<ApiResponse<Event>> getEvent(@PathVariable Long eventId) {
        log.info("GET /api/v1/events/{} - 이벤트 상세 조회", eventId);
        try {
            Event event = ticketingService.getEvent(eventId);
            return ResponseEntity.ok(ApiResponse.success("이벤트를 조회했습니다", event));
        } catch (RuntimeException e) {
            log.error("이벤트 조회 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 티켓 예매
     */
    @PostMapping("/reservations")
    public ResponseEntity<ApiResponse<Reservation>> reserveTicket(
            @Valid @RequestBody ReservationRequest request) {
        log.info("POST /api/v1/reservations - 티켓 예매: {}", request.getEventId());
        try {
            Reservation reservation = ticketingService.reserveTicket(request);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("티켓 예매가 완료되었습니다", reservation));
        } catch (RuntimeException e) {
            log.error("티켓 예매 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 예약 조회
     */
    @GetMapping("/reservations/{reservationCode}")
    public ResponseEntity<ApiResponse<Reservation>> getReservation(
            @PathVariable String reservationCode) {
        log.info("GET /api/v1/reservations/{} - 예약 조회", reservationCode);
        try {
            Reservation reservation = ticketingService.getReservation(reservationCode);
            return ResponseEntity.ok(ApiResponse.success("예약 정보를 조회했습니다", reservation));
        } catch (RuntimeException e) {
            log.error("예약 조회 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.error(e.getMessage()));
        }
    }
    
    /**
     * 예약 취소
     */
    @DeleteMapping("/reservations/{reservationCode}")
    public ResponseEntity<ApiResponse<Void>> cancelReservation(
            @PathVariable String reservationCode) {
        log.info("DELETE /api/v1/reservations/{} - 예약 취소", reservationCode);
        try {
            ticketingService.cancelReservation(reservationCode);
            return ResponseEntity.ok(ApiResponse.success("예약이 취소되었습니다", null));
        } catch (RuntimeException e) {
            log.error("예약 취소 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error(e.getMessage()));
        }
    }
}
