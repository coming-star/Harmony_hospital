package com.neusoft.hisspringboot.modules.doctor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("doctor_schedule_rule")
public class DoctorScheduleRule {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long doctorId;
    private Long scheduleRuleId;
}
