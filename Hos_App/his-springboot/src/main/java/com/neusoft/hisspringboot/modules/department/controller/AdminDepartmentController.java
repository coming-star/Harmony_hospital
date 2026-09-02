package com.neusoft.hisspringboot.modules.department.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.ToggleStatusRequest;
import com.neusoft.hisspringboot.modules.department.entity.Department;
import com.neusoft.hisspringboot.modules.department.service.AdminDepartmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

/**
 * 管理端科室接口：科室分页查询、新增、编辑、启用/停用、逻辑删除。
 */
@Tag(name = "科室管理", description = "科室树查询与后台科室新增、编辑、停用、删除")
@RestController
@RequestMapping("/api/admin/departments")
@RequiredArgsConstructor
public class AdminDepartmentController {

    private final AdminDepartmentService adminDepartmentService;

    /**
     * 分页查询科室：支持名称、类型、上级科室组合筛选。
     */
    @Operation(
            summary = "分页查询科室",
            description = "管理端科室列表，支持按科室名称、科室类型、上级科室筛选；excludeRoot=true 时只返回二级科室（供医生挂科室用）",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/list")
    public ApiResponse<PageResult<Department>> list(
            @Parameter(description = "科室名称（模糊匹配）") @RequestParam(required = false) String name,
            @Parameter(description = "科室类型，如 CLINICAL（临床科室）") @RequestParam(required = false) String departmentType,
            @Parameter(description = "上级科室ID；0 表示一级科室") @RequestParam(required = false) Long parentId,
            @Parameter(description = "是否排除一级科室：true 时只返回二级科室") @RequestParam(required = false) Boolean excludeRoot,
            @Parameter(description = "页码，从 1 开始，默认 1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页条数，默认 10") @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(adminDepartmentService.list(name, departmentType, parentId, excludeRoot, page, size));
    }

    /**
     * 新增科室：parentId=0 为一级科室，否则为指定一级科室下的二级科室。
     */
    @Operation(
            summary = "新增科室",
            description = "新增科室；parentId=0 为一级科室，否则为二级科室（必须引用已存在的一级科室）",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping
    public ApiResponse<Long> create(@Valid @RequestBody Department department) {
        return ApiResponse.success(adminDepartmentService.create(department));
    }

    /**
     * 编辑科室。
     */
    @Operation(
            summary = "编辑科室",
            description = "修改科室名称、编码、描述、排序号等信息",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}")
    public ApiResponse<Void> update(
            @Parameter(description = "科室ID", required = true) @PathVariable Long id,
            @RequestBody Department department
    ) {
        adminDepartmentService.update(id, department);
        return ApiResponse.success();
    }

    /**
     * 启用/停用科室。
     */
    @Operation(
            summary = "启用/停用科室",
            description = "请求体 {\"enabled\": 1} 启用、{\"enabled\": 0} 停用；停用后患者端科室树不再展示",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}/status")
    public ApiResponse<Void> toggleStatus(
            @Parameter(description = "科室ID", required = true) @PathVariable Long id,
            @Valid @RequestBody ToggleStatusRequest request
    ) {
        adminDepartmentService.toggleStatus(id, request.enabled());
        return ApiResponse.success();
    }

    /**
     * 逻辑删除科室：下挂二级科室或医生时拒绝删除。
     */
    @Operation(
            summary = "逻辑删除科室",
            description = "逻辑删除科室；一级科室下仍有二级科室、或科室下仍有医生时返回业务错误",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(
            @Parameter(description = "科室ID", required = true) @PathVariable Long id
    ) {
        adminDepartmentService.delete(id);
        return ApiResponse.success();
    }
}
