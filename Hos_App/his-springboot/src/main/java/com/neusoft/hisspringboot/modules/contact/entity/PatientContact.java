package com.neusoft.hisspringboot.modules.contact.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 就诊人只读模型，供挂号下单校验归属使用；身份证密文/哈希与完整 CRUD 由就诊人模块负责，本期未实现。
 */
@Data
@TableName("patient_contact")
public class PatientContact {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long userId;
    private String name;
    private String phone;
    private String relation;

    @TableLogic
    private Integer deleted;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
