package com.neusoft.hisspringboot.modules.user.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_user")
public class SysUser {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /**
     * 管理员登录账号；患者为空。
     */
    private String username;

    /**
     * 患者登录手机号。
     */
    private String phone;

    private String passwordHash;
    private String nickname;
    private String avatarUrl;

    /**
     * ADMIN：管理员；PATIENT：患者。
     */
    private String userType;

    /**
     * 1：启用；0：禁用。
     */
    private Integer status;

    private LocalDateTime lastLoginAt;

    @TableLogic
    private Integer deleted;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}