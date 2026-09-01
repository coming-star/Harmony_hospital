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

@Tag(name = "科室管理", description = "科室树查询与后台科室新增、编辑、停用、删除")
@RestController
@RequiredArgsConstructor
public class DepartmentController {

    private final DepartmentService departmentService;

    @Operation(
            summary = "查询科室树",
            description = "仅返回已启用科室，parentId=0 的一级科室在根节点展开",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/api/departments/tree")
    public ApiResponse<List<DepartmentTreeNode>> tree() {
        return ApiResponse.success(departmentService.tree());
    }
}
