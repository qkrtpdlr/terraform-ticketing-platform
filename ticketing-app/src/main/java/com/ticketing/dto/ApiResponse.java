package com.ticketing.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApiResponse<T> {
    
    private boolean success;
    private String message;
    private T data;
    private Long timestamp;
    
    public static <T> ApiResponse<T> success(String message, T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .timestamp(System.currentTimeMillis())
                .build();
    }
    
    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .data(null)
                .timestamp(System.currentTimeMillis())
                .build();
    }
}
