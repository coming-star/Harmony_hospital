package com.neusoft.hisspringboot.modules.schedule.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Data
@TableName("schedule_slot")
public class ScheduleSlot {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long scheduleRuleId;
    private Long doctorId;
    private Long departmentId;
    private Long levelId;
    private LocalDate visitDate;
    private LocalTime startTime;
    private LocalTime endTime;
    private Integer totalQuota;
    private Integer remainingQuota;

    /**
     * OPEN/CLOSED/CANCELLED。
     */
    private String status;

    private Integer version;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
