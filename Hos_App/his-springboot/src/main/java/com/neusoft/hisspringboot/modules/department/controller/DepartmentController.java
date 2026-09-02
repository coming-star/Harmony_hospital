package com.neusoft.hisspringboot.modules.department.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.department.dto.DepartmentTreeNode;
import com.neusoft.hisspringboot.modules.department.service.DepartmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 患者端科室接口：查询两级科室树（一级科室 + 二级科室）。
 */
@Tag(name = "科室管理", description = "科室树查询与后台科室新增、编辑、停用、删除")
@RestController
@RequiredArgsConstructor
public class DepartmentController {

    private final DepartmentService departmentService;

    /**
     * 查询科室树：一级科室为根节点，二级科室挂在 children 中。
     */
    @Operation(
            summary = "查询科室树",
            description = "返回两级科室树：parentId=0 的一级科室在根节点，其下二级科室在 children 中；仅返回已启用科室；结果带 Redis 缓存",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/api/departments/tree")
    public ApiResponse<List<DepartmentTreeNode>> tree() {
        return ApiResponse.success(departmentService.tree());
    }
}
