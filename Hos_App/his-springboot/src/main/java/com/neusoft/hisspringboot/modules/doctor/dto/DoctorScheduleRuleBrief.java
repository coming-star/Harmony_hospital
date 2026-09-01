package com.neusoft.hisspringboot.modules.doctor.dto;

public record DoctorScheduleRuleBrief(
        Long levelId,
        String levelName,
        String ruleName,
        Integer weekdayMask,
        String period
) {
}
