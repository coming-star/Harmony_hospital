package com.neusoft.hisspringboot.modules.schedule.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 排班规则模板：不绑定具体医生，多个医生可通过 doctor_schedule_rule 关联表复用同一条规则。
 */
@Data
@TableName("schedule_rule")
@Schema(description = "排班规则")
public class ScheduleRule {

    @Schema(description = "规则ID（新增时不传，由后端生成）", example = "5001")
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    @Schema(description = "挂号级别ID", example = "3003")
    private Long levelId;

    @Schema(description = "规则名称", example = "周一、周三、周五上午")
    private String ruleName;

    /**
     * bit0-6 对应周一至周日。
     */
    @Schema(description = "星期掩码：7 位二进制位，bit0-6 对应周一至周日；如 21（二进制10101）= 周一、周三、周五",
            example = "21")
    private Integer weekdayMask;

    /**
     * MORNING/AFTERNOON/EVENING。
     */
    @Schema(description = "时段：MORNING上午/AFTERNOON下午/EVENING晚间", example = "MORNING")
    private String period;

    /**
     * 时段数组 JSON 文本：[{start,end,quota}]，前端负责序列化/反序列化。
     */
    @Schema(description = "时段 JSON 数组字符串，如 [{\"start\":\"08:00\",\"end\":\"08:30\",\"quota\":4}]",
            example = "[{\"start\":\"08:00\",\"end\":\"08:30\",\"quota\":4}]")
    private String slotsJson;

    @Schema(description = "生效开始日期", example = "2026-09-01")
    private LocalDate effectiveStart;

    @Schema(description = "生效结束日期，null 表示长期有效")
    private LocalDate effectiveEnd;

    @Schema(description = "状态：1 启用 / 0 停用", example = "1")
    private Integer enabled;

    @Schema(description = "逻辑删除标记（系统字段）", hidden = true)
    @TableLogic
    private Integer deleted;

    @Schema(description = "创建时间")
    private LocalDateTime createdAt;

    @Schema(description = "更新时间")
    private LocalDateTime updatedAt;

    @Schema(description = "14 位二进制排班码（响应展示字段，后端计算；新增/编辑时不传）", example = "10101001010100")
    @TableField(exist = false)
    private String ruleCode;

    @Schema(description = "排班概览标签列表，如 [\"周一 上午\",\"周三 上午\"]（响应展示字段，后端计算；新增/编辑时不传）")
    @TableField(exist = false)
    private List<String> scheduleOverview;
}
