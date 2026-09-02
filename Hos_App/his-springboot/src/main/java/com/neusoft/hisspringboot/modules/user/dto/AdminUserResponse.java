package com.neusoft.hisspringboot.modules.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

/**
 * 管理端用户列表项响应。
 */
@Schema(description = "管理端用户信息")
public record AdminUserResponse(
        @Schema(description = "用户ID", example = "10006")
        Long id,

        @Schema(description = "手机号", example = "13800000006")
        String phone,

        @Schema(description = "昵称", example = "赵小明")
        String nickname,

        @Schema(description = "用户类型：PATIENT 患者 / ADMIN 管理员", example = "PATIENT")
        String userType,

        @Schema(description = "状态：1 启用 / 0 停用", example = "1")
        Integer status,

        @Schema(description = "注册时间")
        LocalDateTime createdAt,

        @Schema(description = "最近登录时间，从未登录为 null")
        LocalDateTime lastLoginAt
) {
}
