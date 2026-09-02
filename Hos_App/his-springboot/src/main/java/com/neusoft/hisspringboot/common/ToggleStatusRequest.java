package com.neusoft.hisspringboot.common;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

/**
 * 后台管理列表统一的启用/停用请求体：{"enabled": 1|0}。
 *
 * @param enabled 目标状态：1 启用 / 0 停用
 */
@Schema(description = "启用/停用请求体")
public record ToggleStatusRequest(

        @Schema(description = "目标状态：1 启用 / 0 停用", example = "1",
                requiredMode = Schema.RequiredMode.REQUIRED)
        @NotNull(message = "enabled 不能为空")
        Integer enabled
) {
}
