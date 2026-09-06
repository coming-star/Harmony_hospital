package com.neusoft.hisspringboot.modules.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;

/**
 * 修改当前登录用户资料请求。
 * 仅支持修改昵称和头像；手机号、密码等不在此处修改。
 * 两个字段均可选，传哪个改哪个。
 */
@Schema(description = "修改个人资料请求")
public record UpdateMeRequest(

        @Schema(description = "昵称，1-20 字符", example = "张三")
        @Size(min = 1, max = 20, message = "昵称长度需在 1-20 字符之间")
        String nickname,

        @Schema(description = "头像 URL（由 /api/upload/avatar 返回）",
                example = "http://localhost:8081/static/avatars/abc.png")
        String avatarUrl
) {
}
