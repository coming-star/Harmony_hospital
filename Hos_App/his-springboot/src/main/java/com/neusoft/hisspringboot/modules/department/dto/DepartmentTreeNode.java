package com.neusoft.hisspringboot.modules.department.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

/**
 * 科室树节点：一级科室的 children 为其下二级科室。
 */
@Schema(description = "科室树节点")
public record DepartmentTreeNode(
        @Schema(description = "科室ID", example = "2001")
        Long id,

        @Schema(description = "科室编码", example = "MED")
        String code,

        @Schema(description = "科室名称", example = "内科")
        String name,

        @Schema(description = "科室简介", example = "心血管、呼吸、消化、神经、内分泌等内脏系统疾病。")
        String description,

        @Schema(description = "排序号（越小越靠前）", example = "10")
        Integer sortNo,

        @Schema(description = "下级科室列表（二级科室）；一级科室以外为空数组")
        List<DepartmentTreeNode> children
) {
}
