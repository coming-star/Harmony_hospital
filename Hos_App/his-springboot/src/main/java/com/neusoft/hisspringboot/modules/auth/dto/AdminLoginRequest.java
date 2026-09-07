package com.neusoft.hisspringboot.modules.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Schema(description = "管理员登录请求")
public record AdminLoginRequest(

        @Schema(description = "管理员用户名", example = "admin", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "管理员账号不能为空")
        String username,

        @Schema(description = "登录密码", example = "admin123", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "密码不能为空")
        @Size(min = 6, max = 16, message = "密码长度应为6到16位")
        String password
) {
}
