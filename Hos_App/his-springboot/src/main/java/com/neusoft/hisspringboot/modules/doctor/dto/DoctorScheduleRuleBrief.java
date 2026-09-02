package com.neusoft.hisspringboot.modules.doctor.dto;

import io.swagger.v3.oas.annotations.media.Schema;

/**
 * 医生关联排班规则摘要（医生列表中展示排班概览用）。
 */
@Schema(description = "医生排班规则摘要")
public record DoctorScheduleRuleBrief(
        @Schema(description = "排班规则ID", example = "5001")
        Long ruleId,

        @Schema(description = "挂号级别ID", example = "3003")
        Long levelId,

        @Schema(description = "挂号级别名称", example = "主任医师号")
        String levelName,

        @Schema(description = "规则名称", example = "周一、周三、周五上午")
        String ruleName,

        @Schema(description = "星期掩码：bit0-6 对应周一至周日，如 21=周一三五", example = "21")
        Integer weekdayMask,

        @Schema(description = "时段：MORNING上午/AFTERNOON下午/EVENING晚间", example = "MORNING")
        String period
) {
}
