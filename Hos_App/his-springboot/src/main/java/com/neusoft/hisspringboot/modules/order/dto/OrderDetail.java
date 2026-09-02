package com.neusoft.hisspringboot.modules.order.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * 挂号订单详情（列表和详情接口共用），医生/科室/号别名称为下单时快照。
 */
@Schema(description = "挂号订单详情")
public record OrderDetail(
        @Schema(description = "订单ID", example = "70001")
        Long id,

        @Schema(description = "订单号", example = "SEED70001")
        String orderNo,

        @Schema(description = "订单状态：PENDING_PAYMENT待支付/PAID已支付/COMPLETED已完成/CANCELLED已取消",
                example = "PAID", allowableValues = {"PENDING_PAYMENT", "PAID", "COMPLETED", "CANCELLED"})
        String status,

        @Schema(description = "号源ID", example = "601031")
        Long slotId,

        @Schema(description = "医生ID", example = "4001")
        Long doctorId,

        @Schema(description = "医生姓名（下单时快照）", example = "陈明远")
        String doctorName,

        @Schema(description = "科室ID", example = "2101")
        Long departmentId,

        @Schema(description = "科室名称（下单时快照）", example = "心血管内科")
        String departmentName,

        @Schema(description = "挂号级别ID", example = "3003")
        Long levelId,

        @Schema(description = "挂号级别名称（下单时快照）", example = "主任医师号")
        String levelName,

        @Schema(description = "就诊日期", example = "2026-09-04")
        LocalDate visitDate,

        @Schema(description = "时段开始时间", example = "08:00:00")
        LocalTime startTime,

        @Schema(description = "时段结束时间", example = "08:30:00")
        LocalTime endTime,

        @Schema(description = "挂号费用（单位：分）", example = "5000")
        Integer amountFen,

        @Schema(description = "支付截止时间，逾期订单自动取消")
        LocalDateTime expiredAt,

        @Schema(description = "支付时间，未支付为 null")
        LocalDateTime paidAt,

        @Schema(description = "取消时间，未取消为 null")
        LocalDateTime cancelledAt,

        @Schema(description = "取消原因：USER 用户取消 / ADMIN 管理员取消")
        String cancelReason,

        @Schema(description = "订单创建时间")
        LocalDateTime createdAt,

        @Schema(description = "就诊人姓名", example = "张建国")
        String contactName,

        @Schema(description = "就诊人手机号", example = "13900000002")
        String contactPhone
) {
}
