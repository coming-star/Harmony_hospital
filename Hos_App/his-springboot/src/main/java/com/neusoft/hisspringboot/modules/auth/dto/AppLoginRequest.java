package com.neusoft.hisspringboot.modules.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@Schema(description = "患者登录请求")
public record AppLoginRequest(

        @Schema(description = "手机号（注册时使用的手机号）", example = "13800000002",
                requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
        String phone,

        @Schema(description = "登录密码", example = "12345678", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "密码不能为空")
        @Size(min = 8, max = 64, message = "密码长度应为8到64位")
        String password
) {
}
