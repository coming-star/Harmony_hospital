package com.neusoft.hisspringboot.modules.department.dto;

import java.util.List;

public record DepartmentTreeNode(
        Long id,
        String code,
        String name,
        String description,
        Integer sortNo,
        List<DepartmentTreeNode> children
) {
}
