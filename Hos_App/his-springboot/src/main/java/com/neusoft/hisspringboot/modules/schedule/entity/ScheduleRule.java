package com.neusoft.hisspringboot.modules.schedule.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("schedule_rule")
public class ScheduleRule {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long doctorId;
    private Long levelId;
    private String ruleName;

    /**
     * bit0-6 对应周一至周日。
     */
    private Integer weekdayMask;

    /**
     * MORNING/AFTERNOON/EVENING。
     */
    private String period;

    /**
     * 时段数组 JSON 文本：[{start,end,quota}]，前端负责序列化/反序列化。
     */
    private String slotsJson;

    private LocalDate effectiveStart;
    private LocalDate effectiveEnd;
    private Integer enabled;

    @TableLogic
    private Integer deleted;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
