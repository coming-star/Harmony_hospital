package com.neusoft.hisspringboot.modules.doctor.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 医生可挂号级别摘要。
 */
@Schema(description = "挂号级别摘要")
public record DoctorLevelBrief(
        @Schema(description = "挂号级别ID", example = "3003")
        Long levelId,

        @Schema(description = "级别编码", example = "CHIEF")
        String code,

        @Schema(description = "级别名称", example = "主任医师号")
        String name,

        @Schema(description = "挂号费用（单位：分）", example = "5000")
        Integer feeFen
) {
}
