package com.neusoft.hisspringboot.modules.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminLoginRequest(

        @NotBlank(message = "管理员账号不能为空")
        String username,

        @NotBlank(message = "密码不能为空")
        @Size(min = 6, max = 64, message = "密码长度不合法")
        String password
) {
}