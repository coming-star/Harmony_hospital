package com.neusoft.hisspringboot.common;

import jakarta.validation.constraints.NotNull;

/**
 * 后台管理列表统一的启用/停用请求体：{"enabled": 1|0}。
 */
public record ToggleStatusRequest(

        @NotNull(message = "enabled 不能为空")
        Integer enabled
) {
}
