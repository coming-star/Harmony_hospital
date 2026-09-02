package com.neusoft.hisspringboot.modules.doctor.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

/**
 * 医生详情响应：患者端查询医生信息时返回。
 */
@Schema(description = "医生详情")
public record DoctorDetailResponse(
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

        @Schema(description = "医生简介", example = "从事心血管内科临床与教学工作二十余年，擅长高血压、冠心病及心律失常管理。")
        String introduction,

        @Schema(description = "可提供的挂号级别列表")
        List<DoctorLevelBrief> levels
) {
}
