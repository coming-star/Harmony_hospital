package com.neusoft.hisspringboot.modules.doctor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("doctor")
public class Doctor {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private String name;
    private Long departmentId;
    private String title;
    private String avatarUrl;
    private String introduction;
    private Integer enabled;

    @TableLogic
    private Integer deleted;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
