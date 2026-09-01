package com.neusoft.hisspringboot.modules.order.dto;

import java.time.LocalDate;

/**
 * 近 7 天预约量趋势统计项。
 */
public record DailyCount(LocalDate date, long count) {
}
