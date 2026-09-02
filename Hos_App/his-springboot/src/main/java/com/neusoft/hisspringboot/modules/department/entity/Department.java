package com.neusoft.hisspringboot.modules.department.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("department")
public class Department {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private String code;
    private String name;

    /**
     * 0 表示一级科室。
     */
    private Long parentId;

    private String departmentType;
    private String description;
    private Integer sortNo;
    private Integer enabled;

    @TableLogic
    private Integer deleted;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
