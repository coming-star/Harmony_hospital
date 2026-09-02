package com.neusoft.hisspringboot.modules.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

/**
 * 管理端新增/编辑患者账号请求。
 */
@Schema(description = "新增/编辑用户请求")
public record AdminUserRequest(

        @Schema(description = "手机号（11 位，作为登录账号）", example = "13800000006",
                requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "手机号不能为空")
        String phone,

        @Schema(description = "昵称", example = "赵小明", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "昵称不能为空")
        String nickname,

        /**
         * 新增时必填；编辑时留空表示不修改密码。
         */
        @Schema(description = "登录密码（8~64 位）；新增时必填，编辑时留空表示不修改密码", example = "12345678")
        String password
) {
}
