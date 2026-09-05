package com.neusoft.hisspringboot.modules.schedule.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDate;
import java.time.LocalTime;

/**
 * 号源摘要：查询号源接口返回的可预约时段。
 */
@Schema(description = "号源摘要")
public record SlotSummary(
        @Schema(description = "号源ID（下单时传 slotId）", example = "601031")
        @JsonSerialize(using = ToStringSerializer.class)
        Long slotId,

        @Schema(description = "医生ID", example = "4001")
        Long doctorId,

        @Schema(description = "医生姓名", example = "陈明远")
        String doctorName,

        @Schema(description = "科室ID", example = "2101")
        Long departmentId,

        @Schema(description = "挂号级别ID", example = "3003")
        Long levelId,

        @Schema(description = "挂号级别名称", example = "主任医师号")
        String levelName,

        @Schema(description = "挂号费用（单位：分）", example = "5000")
        Integer feeFen,

        @Schema(description = "就诊日期", example = "2026-09-04")
        LocalDate visitDate,

        @JsonFormat(pattern = "HH:mm:ss")
        @Schema(description = "时段开始时间", example = "08:00:00")
        LocalTime startTime,

        @JsonFormat(pattern = "HH:mm:ss")
        @Schema(description = "时段结束时间", example = "08:30:00")
        LocalTime endTime,

        @Schema(description = "剩余号源数", example = "3")
        Integer remainingQuota
) {
}
