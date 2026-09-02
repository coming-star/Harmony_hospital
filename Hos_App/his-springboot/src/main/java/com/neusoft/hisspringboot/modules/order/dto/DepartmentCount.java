package com.neusoft.hisspringboot.modules.order.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 科室预约量统计项。
 *
 * @param name  科室名称
 * @param count 该科室预约订单量
 */
@Schema(description = "科室预约量统计项")
public record DepartmentCount(
        @Schema(description = "科室名称", example = "心血管内科")
        String name,

        @Schema(description = "该科室预约订单量", example = "5")
        long count
) {
}
