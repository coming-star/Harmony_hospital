package com.neusoft.hisspringboot.modules.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

@Schema(description = "患者注册请求")
public record AppRegisterRequest(

        @Schema(description = "手机号（11 位，作为登录账号）", example = "13800000005",
                requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
        String phone,

        @Schema(description = "登录密码（8~16 位）", example = "12345678",
                requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "密码不能为空")
        @Size(min = 8, max = 16, message = "密码长度应为8到16位")
        String password,

        @Schema(description = "昵称", example = "赵小明", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "昵称不能为空")
        @Size(max = 50, message = "昵称不能超过50个字符")
        String nickname
) {
}
