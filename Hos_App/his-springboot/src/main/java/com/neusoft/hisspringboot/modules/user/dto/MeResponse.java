package com.neusoft.hisspringboot.modules.user.dto;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;

/**
 * /api/me 返回的当前登录用户完整信息（含昵称、头像、手机号）。
 * 这些字段不在 JWT 中，由控制器按 userId 查库后填充。
 */
@Schema(description = "当前登录用户信息")
public record MeResponse(

        @Schema(description = "用户ID（字符串，避免前端精度丢失）", example = "10002")
        @JsonSerialize(using = ToStringSerializer.class)
        Long userId,

        @Schema(description = "用户类型：PATIENT 患者 / ADMIN 管理员", example = "PATIENT",
                allowableValues = {"PATIENT", "ADMIN"})
        String userType,

        @Schema(description = "昵称", example = "张三")
        String nickname,

        @Schema(description = "头像 URL，未设置为空", example = "http://localhost:8081/static/avatars/abc.png")
        String avatarUrl,

        @Schema(description = "手机号（患者）", example = "13900000001")
        String phone
) {
}
