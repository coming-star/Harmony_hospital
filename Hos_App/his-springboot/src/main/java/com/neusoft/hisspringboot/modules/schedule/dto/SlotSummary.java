package com.neusoft.hisspringboot.modules.schedule.dto;

import java.time.LocalDate;
import java.time.LocalTime;

public record SlotSummary(
        Long slotId,
        Long doctorId,
        String doctorName,
        String doctorAvatarUrl,
        Long departmentId,
        Long levelId,
        String levelName,
        Integer feeFen,
        LocalDate visitDate,
        LocalTime startTime,
        LocalTime endTime,
        Integer remainingQuota
) {
}
