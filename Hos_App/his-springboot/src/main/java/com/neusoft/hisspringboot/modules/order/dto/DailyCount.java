package com.neusoft.hisspringboot.modules.order.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDate;

/**
 * 近 7 天预约量趋势统计项。
 *
 * @param date  日期
 * @param count 当日预约订单量
 */
@Schema(description = "近7天预约量趋势统计项")
public record DailyCount(
        @Schema(description = "日期", example = "2026-09-03")
        LocalDate date,

        @Schema(description = "当日预约订单量", example = "3")
        long count
) {
}
