package com.neusoft.hisspringboot.modules.doctor.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public record AdminDoctorRequest(
        @NotBlank(message = "医生姓名不能为空")
        String name,

        @NotNull(message = "所属科室不能为空")
        Long departmentId,

        String title,
        String introduction,
        List<Long> levelIds,
        List<Long> scheduleRuleIds
) {
}
