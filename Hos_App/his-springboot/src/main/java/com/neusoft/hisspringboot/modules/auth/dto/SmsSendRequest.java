package com.neusoft.hisspringboot.modules.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

@Schema(description = "发送短信验证码请求（本地模拟，验证码打印在后端日志中）")
public record SmsSendRequest(

        @Schema(description = "手机号", example = "13800000002", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
        String phone,

        @Schema(description = "验证码用途：LOGIN=短信登录（未注册自动注册），RESET_PASSWORD=找回密码",
                example = "LOGIN", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "验证码用途不能为空")
        @Pattern(regexp = "^(LOGIN|RESET_PASSWORD)$", message = "验证码用途不正确")
        String scene
) {
}
