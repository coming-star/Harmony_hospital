package com.neusoft.hisspringboot.modules.auth.dto;

public record LoginResponse(
        String accessToken,
        String tokenType,
        Long userId,
        String nickname,
        String userType
) {
}