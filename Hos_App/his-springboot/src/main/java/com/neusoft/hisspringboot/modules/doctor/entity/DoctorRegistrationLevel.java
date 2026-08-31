package com.neusoft.hisspringboot.modules.doctor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("doctor_registration_level")
public class DoctorRegistrationLevel {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long doctorId;
    private Long levelId;
    private Integer enabled;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
