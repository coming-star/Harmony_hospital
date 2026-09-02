package com.neusoft.hisspringboot.modules.doctor.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.List;

/**
 * 管理端新增/编辑医生请求。
 */
@Schema(description = "新增/编辑医生请求")
public record AdminDoctorRequest(

        @Schema(description = "医生姓名", example = "陈明远", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "医生姓名不能为空")
        String name,

        @Schema(description = "所属二级科室ID", example = "2101", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotNull(message = "所属科室不能为空")
        Long departmentId,

        @Schema(description = "职称", example = "主任医师")
        String title,

        @Schema(description = "医生简介", example = "擅长高血压、冠心病及心律失常管理。")
        String introduction,

        @Schema(description = "可挂号级别ID数组（多对多），如 [3001,3002]")
        List<Long> levelIds,

        @Schema(description = "排班规则模板ID数组（多对多），如 [5001]")
        List<Long> scheduleRuleIds
) {
}
