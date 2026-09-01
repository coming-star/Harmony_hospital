package com.neusoft.hisspringboot.modules.doctor.dto;

public record DoctorScheduleRuleBrief(
        Long ruleId,
        Long levelId,
        String levelName,
        String ruleName,
        Integer weekdayMask,
        String period
) {
}
