package com.ticketing.service;

import com.ticketing.dto.ReservationRequest;
import com.ticketing.model.Event;
import com.ticketing.model.Reservation;
import com.ticketing.repository.EventRepository;
import com.ticketing.repository.ReservationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class TicketingService {
    
    private final EventRepository eventRepository;
    private final ReservationRepository reservationRepository;
    private final RedisTemplate<String, Object> redisTemplate;
    
    private static final String SEAT_LOCK_PREFIX = "seat:lock:";
    private static final String EVENT_CACHE_PREFIX = "event:";
    
    /**
     * 모든 이벤트 조회
     */
    public List<Event> getAllEvents() {
        log.info("모든 이벤트 조회");
        return eventRepository.findAll();
    }
    
    /**
     * 예매 가능한 이벤트 조회
     */
    public List<Event> getAvailableEvents() {
        log.info("예매 가능한 이벤트 조회");
        
        // Redis 캐시 확인
        String cacheKey = EVENT_CACHE_PREFIX + "available";
        List<Event> cachedEvents = (List<Event>) redisTemplate.opsForValue().get(cacheKey);
        
        if (cachedEvents != null) {
            log.info("캐시에서 이벤트 반환");
            return cachedEvents;
        }
        
        // DB 조회
        List<Event> events = eventRepository.findAvailableEvents();
        
        // Redis 캐시 저장 (5분)
        redisTemplate.opsForValue().set(cacheKey, events, 5, TimeUnit.MINUTES);
        
        return events;
    }
    
    /**
     * 이벤트 상세 조회
     */
    public Event getEvent(Long eventId) {
        log.info("이벤트 조회: {}", eventId);
        
        // Redis 캐시 확인
        String cacheKey = EVENT_CACHE_PREFIX + eventId;
        Event cachedEvent = (Event) redisTemplate.opsForValue().get(cacheKey);
        
        if (cachedEvent != null) {
            return cachedEvent;
        }
        
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new RuntimeException("이벤트를 찾을 수 없습니다: " + eventId));
        
        // 캐시 저장
        redisTemplate.opsForValue().set(cacheKey, event, 5, TimeUnit.MINUTES);
        
        return event;
    }
    
    /**
     * 티켓 예매 (분산 락 사용)
     */
    @Transactional
    public Reservation reserveTicket(ReservationRequest request) {
        log.info("티켓 예매 시작: 이벤트 ID = {}, 수량 = {}", request.getEventId(), request.getQuantity());
        
        String lockKey = SEAT_LOCK_PREFIX + request.getEventId();
        
        try {
            // Redis 분산 락 획득 (최대 5초 대기)
            Boolean lockAcquired = redisTemplate.opsForValue()
                    .setIfAbsent(lockKey, "locked", 10, TimeUnit.SECONDS);
            
            if (Boolean.FALSE.equals(lockAcquired)) {
                throw new RuntimeException("다른 사용자가 예매 중입니다. 잠시 후 다시 시도해주세요.");
            }
            
            // 이벤트 조회
            Event event = eventRepository.findById(request.getEventId())
                    .orElseThrow(() -> new RuntimeException("이벤트를 찾을 수 없습니다"));
            
            // 좌석 확인
            if (event.getAvailableSeats() < request.getQuantity()) {
                throw new RuntimeException("남은 좌석이 부족합니다. (남은 좌석: " + event.getAvailableSeats() + "석)");
            }
            
            // 좌석 차감
            event.setAvailableSeats(event.getAvailableSeats() - request.getQuantity());
            
            // 매진 처리
            if (event.getAvailableSeats() == 0) {
                event.setStatus("SOLD_OUT");
            }
            
            eventRepository.save(event);
            
            // 예약 생성
            Reservation reservation = Reservation.builder()
                    .event(event)
                    .userName(request.getUserName())
                    .email(request.getEmail())
                    .phone(request.getPhone())
                    .quantity(request.getQuantity())
                    .totalPrice(event.getPrice() * request.getQuantity())
                    .status("CONFIRMED")
                    .build();
            
            reservation.setConfirmedAt(LocalDateTime.now());
            
            Reservation savedReservation = reservationRepository.save(reservation);
            
            // 캐시 무효화
            redisTemplate.delete(EVENT_CACHE_PREFIX + request.getEventId());
            redisTemplate.delete(EVENT_CACHE_PREFIX + "available");
            
            log.info("티켓 예매 완료: 예약 코드 = {}", savedReservation.getReservationCode());
            
            return savedReservation;
            
        } finally {
            // 락 해제
            redisTemplate.delete(lockKey);
        }
    }
    
    /**
     * 예약 조회
     */
    public Reservation getReservation(String reservationCode) {
        log.info("예약 조회: {}", reservationCode);
        return reservationRepository.findByReservationCode(reservationCode)
                .orElseThrow(() -> new RuntimeException("예약을 찾을 수 없습니다: " + reservationCode));
    }
    
    /**
     * 예약 취소
     */
    @Transactional
    public void cancelReservation(String reservationCode) {
        log.info("예약 취소: {}", reservationCode);
        
        Reservation reservation = reservationRepository.findByReservationCode(reservationCode)
                .orElseThrow(() -> new RuntimeException("예약을 찾을 수 없습니다"));
        
        if ("CANCELLED".equals(reservation.getStatus())) {
            throw new RuntimeException("이미 취소된 예약입니다");
        }
        
        // 좌석 복구
        Event event = reservation.getEvent();
        event.setAvailableSeats(event.getAvailableSeats() + reservation.getQuantity());
        
        if ("SOLD_OUT".equals(event.getStatus())) {
            event.setStatus("AVAILABLE");
        }
        
        eventRepository.save(event);
        
        // 예약 취소
        reservation.setStatus("CANCELLED");
        reservationRepository.save(reservation);
        
        // 캐시 무효화
        redisTemplate.delete(EVENT_CACHE_PREFIX + event.getId());
        redisTemplate.delete(EVENT_CACHE_PREFIX + "available");
        
        log.info("예약 취소 완료");
    }
}
