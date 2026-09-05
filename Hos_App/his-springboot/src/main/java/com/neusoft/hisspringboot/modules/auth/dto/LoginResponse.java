package com.neusoft.hisspringboot.modules.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 登录成功响应体。
 *
 * @param accessToken 访问令牌（JWT），后续请求放入请求头 Authorization: Bearer {token}
 * @param tokenType   令牌类型，固定为 Bearer
 * @param userId      用户ID
 * @param nickname    用户昵称
 * @param userType    用户类型：PATIENT 患者 / ADMIN 管理员
 */
@Schema(description = "登录成功响应")
public record LoginResponse(
        @Schema(description = "访问令牌（JWT），后续请求放入请求头 Authorization: Bearer {token}",
                example = "eyJhbGciOiJIUzI1NiJ9.xxxx.yyyy")
        String accessToken,

        @Schema(description = "令牌类型，固定为 Bearer", example = "Bearer")
        String tokenType,

        @Schema(description = "用户ID", example = "10002")
        Long userId,

        @Schema(description = "用户昵称", example = "张晓晨")
        String nickname,

        @Schema(description = "用户手机号", example = "13800000002")
        String phone,

        @Schema(description = "用户类型：PATIENT 患者 / ADMIN 管理员", example = "PATIENT",
                allowableValues = {"PATIENT", "ADMIN"})
        String userType
) {
}
