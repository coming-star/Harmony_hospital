package com.neusoft.hisspringboot.modules.user.dto;

import java.time.LocalDateTime;

public record AdminUserResponse(
        Long id,
        String phone,
        String nickname,
        String userType,
        Integer status,
        LocalDateTime createdAt,
        LocalDateTime lastLoginAt
) {
}
