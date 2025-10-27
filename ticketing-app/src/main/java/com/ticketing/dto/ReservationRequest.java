package com.ticketing.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReservationRequest {
    
    @NotNull(message = "이벤트 ID는 필수입니다")
    private Long eventId;
    
    @NotBlank(message = "이름은 필수입니다")
    @Size(min = 2, max = 50, message = "이름은 2-50자 사이여야 합니다")
    private String userName;
    
    @NotBlank(message = "이메일은 필수입니다")
    @Email(message = "올바른 이메일 형식이 아닙니다")
    private String email;
    
    @NotBlank(message = "전화번호는 필수입니다")
    @Pattern(regexp = "^\\d{2,3}-\\d{3,4}-\\d{4}$", message = "올바른 전화번호 형식이 아닙니다 (예: 010-1234-5678)")
    private String phone;
    
    @NotNull(message = "수량은 필수입니다")
    @Min(value = 1, message = "최소 1장 이상 예매해야 합니다")
    @Max(value = 4, message = "최대 4장까지 예매 가능합니다")
    private Integer quantity;
}
