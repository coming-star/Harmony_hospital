package com.neusoft.hisspringboot.modules.user.dto;

import jakarta.validation.constraints.NotBlank;

public record AdminUserRequest(
        @NotBlank(message = "手机号不能为空")
        String phone,

        @NotBlank(message = "昵称不能为空")
        String nickname,

        /**
         * 新增时必填；编辑时留空表示不修改密码。
         */
        String password
) {
}
