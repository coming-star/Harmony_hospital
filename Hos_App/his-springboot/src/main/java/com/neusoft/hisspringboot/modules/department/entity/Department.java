package com.neusoft.hisspringboot.modules.department.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 科室实体：两级结构，parentId=0 为一级科室，否则为二级科室。
 */
@Data
@TableName("department")
@Schema(description = "科室信息")
public class Department {

    @Schema(description = "科室ID（新增时不传，由后端生成）", example = "2105")
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    @Schema(description = "科室编码", example = "MED-ENDO")
    private String code;

    @Schema(description = "科室名称", example = "内分泌科")
    private String name;

    /**
     * 0 表示一级科室。
     */
    @Schema(description = "上级科室ID；0 表示一级科室", example = "2001")
    private Long parentId;

    @Schema(description = "科室类型：CLINICAL 临床科室", example = "CLINICAL")
    private String departmentType;

    @Schema(description = "科室简介", example = "糖尿病、甲状腺、痛风及代谢性疾病。")
    private String description;

    @Schema(description = "排序号（越小越靠前）", example = "15")
    private Integer sortNo;

    @Schema(description = "状态：1 启用 / 0 停用", example = "1")
    private Integer enabled;

    @Schema(description = "上级科室名称（响应展示字段，后端计算；新增/编辑时不传）", example = "内科")
    @TableField(exist = false)
    private String parentName;

    @Schema(description = "逻辑删除标记（系统字段）", hidden = true)
    @TableLogic
    private Integer deleted;

    @Schema(description = "创建时间")
    private LocalDateTime createdAt;

    @Schema(description = "更新时间")
    private LocalDateTime updatedAt;
}
