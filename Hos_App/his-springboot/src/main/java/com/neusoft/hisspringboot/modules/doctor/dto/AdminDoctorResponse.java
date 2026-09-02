package com.neusoft.hisspringboot.modules.doctor.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

/**
 * 管理端医生列表项响应。
 */
@Schema(description = "管理端医生信息")
public record AdminDoctorResponse(
        @Schema(description = "医生ID", example = "4001")
        Long id,

        @Schema(description = "医生姓名", example = "陈明远")
        String name,

        @Schema(description = "所属二级科室ID", example = "2101")
        Long departmentId,

        @Schema(description = "所属科室名称", example = "心血管内科")
        String departmentName,

        @Schema(description = "职称", example = "主任医师")
        String title,

        @Schema(description = "医生简介")
        String introduction,

        @Schema(description = "状态：1 启用 / 0 停用", example = "1")
        Integer enabled,

        @Schema(description = "可挂号级别ID数组")
        List<Long> levelIds,

        @Schema(description = "关联的排班规则摘要列表")
        List<DoctorScheduleRuleBrief> scheduleRules
) {
}
