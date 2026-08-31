package com.neusoft.hisspringboot.modules.doctor.dto;

public record DoctorLevelBrief(
        Long levelId,
        String code,
        String name,
        Integer feeFen
) {
}
