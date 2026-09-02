package com.neusoft.hisspringboot.security;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 登录态用户信息（JWT 解析后放入 SecurityContext），也是 /api/me 的返回内容。
 *
 * @param userId   用户ID
 * @param userType 用户类型：PATIENT 患者 / ADMIN 管理员
 * @param jti      Token 唯一标识（登出时加入黑名单用）
 */
@Schema(description = "当前登录用户信息")
public record LoginUser(
        @Schema(description = "用户ID", example = "10002")
        Long userId,

        @Schema(description = "用户类型：PATIENT 患者 / ADMIN 管理员", example = "PATIENT",
                allowableValues = {"PATIENT", "ADMIN"})
        String userType,

        @Schema(description = "Token 唯一标识，登出时据此加入黑名单")
        String jti
) {
}
