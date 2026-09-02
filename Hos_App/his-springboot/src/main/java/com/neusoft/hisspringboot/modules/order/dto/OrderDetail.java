package com.neusoft.hisspringboot.modules.order.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

public record OrderDetail(
        Long id,
        String orderNo,
        String status,
        Long slotId,
        Long doctorId,
        String doctorName,
        Long departmentId,
        String departmentName,
        Long levelId,
        String levelName,
        LocalDate visitDate,
        LocalTime startTime,
        LocalTime endTime,
        Integer amountFen,
        LocalDateTime expiredAt,
        LocalDateTime paidAt,
        LocalDateTime cancelledAt,
        String cancelReason,
        LocalDateTime createdAt
) {
}
