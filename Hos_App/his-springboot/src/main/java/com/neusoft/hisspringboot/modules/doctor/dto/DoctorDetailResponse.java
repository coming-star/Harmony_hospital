package com.neusoft.hisspringboot.modules.doctor.dto;

import java.util.List;

public record DoctorDetailResponse(
        Long id,
        String name,
        Long departmentId,
        String departmentName,
        String title,
        String avatarUrl,
        String introduction,
        List<DoctorLevelBrief> levels
) {
}
