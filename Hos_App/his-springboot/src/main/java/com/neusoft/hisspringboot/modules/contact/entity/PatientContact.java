package com.neusoft.hisspringboot.modules.contact.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 就诊人模型：一个登录账号可绑定多个就诊人（帮家人挂号），下单时选择就诊人。
 * 身份证采用 AES-GCM 加密存储（id_card_cipher），SHA-256 哈希用于判重（id_card_hash）；
 * 明文绝不回显，仅在列表/详情中返回脱敏展示字段 idCardMasked。
 */
@Data
@TableName("patient_contact")
@Schema(description = "就诊人信息")
public class PatientContact {

    @Schema(description = "就诊人ID", example = "4801")
    @TableId(type = IdType.ASSIGN_ID)
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    @Schema(description = "所属登录账号ID（后端按登录态自动填充，请求时无需传）", example = "10002")
    private Long userId;

    @Schema(description = "就诊人姓名", example = "张建国")
    private String name;

    @Schema(description = "就诊人手机号", example = "13900000002")
    private String phone;

    /** 与账号本人的关系：SELF本人/PARENT父母/CHILD子女/SPOUSE配偶/OTHER其他 */
    @Schema(description = "与账号本人的关系：SELF本人/PARENT父母/CHILD子女/SPOUSE配偶/OTHER其他",
            example = "PARENT", allowableValues = {"SELF", "PARENT", "CHILD", "SPOUSE", "OTHER"})
    private String relation;

    /** 身份证 AES-GCM 密文（不返回前端） */
    @JsonIgnore
    @Schema(hidden = true)
    private byte[] idCardCipher;

    /** 身份证 SHA-256 哈希，用于同账号判重（不返回前端） */
    @JsonIgnore
    @Schema(hidden = true)
    private String idCardHash;

    /** 脱敏身份证（非数据库字段，Service 层填充），如 110***********1234 */
    @TableField(exist = false)
    @Schema(description = "脱敏身份证号（如 110***********1234），未填则为空", example = "110***********1234")
    private String idCardMasked;

    @Schema(description = "逻辑删除标记（系统字段）", hidden = true)
    @TableLogic
    private Integer deleted;

    @Schema(description = "创建时间")
    private LocalDateTime createdAt;

    @Schema(description = "更新时间")
    private LocalDateTime updatedAt;
}
