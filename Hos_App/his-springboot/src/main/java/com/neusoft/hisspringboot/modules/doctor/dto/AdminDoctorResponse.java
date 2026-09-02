package com.neusoft.hisspringboot.modules.doctor.dto;

import java.util.List;

public record AdminDoctorResponse(
        Long id,
        String name,
        Long departmentId,
        String title,
        String avatarUrl,
        String introduction,
        Integer enabled,
        List<Long> levelIds
) {
}
