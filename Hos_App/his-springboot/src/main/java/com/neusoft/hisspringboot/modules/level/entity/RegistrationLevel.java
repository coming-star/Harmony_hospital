package com.neusoft.hisspringboot.modules.level.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 挂号级别实体：普通号、专家号、主任医师号等。
 */
@Data
@TableName("registration_level")
@Schema(description = "挂号级别")
public class RegistrationLevel {

    @Schema(description = "级别ID（新增时不传，由后端生成）", example = "3001")
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    @Schema(description = "级别编码", example = "GENERAL")
    private String code;

    @Schema(description = "级别名称", example = "普通号")
    private String name;

    @Schema(description = "挂号费用（单位：分）", example = "1000")
    private Integer feeFen;

    @Schema(description = "每个时段默认号源数", example = "20")
    private Integer defaultQuota;

    @Schema(description = "排序号（越小越靠前）", example = "10")
    private Integer sortNo;

    @Schema(description = "状态：1 启用 / 0 停用", example = "1")
    private Integer enabled;

    @Schema(description = "逻辑删除标记（系统字段）", hidden = true)
    @TableLogic
    private Integer deleted;

    @Schema(description = "创建时间")
    private LocalDateTime createdAt;

    @Schema(description = "更新时间")
    private LocalDateTime updatedAt;
}
