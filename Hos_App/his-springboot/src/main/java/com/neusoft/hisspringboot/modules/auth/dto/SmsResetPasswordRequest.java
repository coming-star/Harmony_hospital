package com.neusoft.hisspringboot.modules.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@Schema(description = "短信验证码找回密码请求")
public record SmsResetPasswordRequest(

        @Schema(description = "手机号", example = "13800000002", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
        String phone,

        @Schema(description = "6 位短信验证码", example = "123456", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "验证码不能为空")
        @Pattern(regexp = "^\\d{6}$", message = "验证码应为6位数字")
        String code,

        @Schema(description = "新密码", example = "12345678", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "新密码不能为空")
        @Size(min = 8, max = 64, message = "密码长度应为8到64位")
        String newPassword
) {
}
