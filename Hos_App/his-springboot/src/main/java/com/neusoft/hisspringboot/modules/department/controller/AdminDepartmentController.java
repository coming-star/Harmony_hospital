package com.neusoft.hisspringboot.modules.department.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.ToggleStatusRequest;
import com.neusoft.hisspringboot.modules.department.entity.Department;
import com.neusoft.hisspringboot.modules.department.service.AdminDepartmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

@Tag(name = "科室管理", description = "科室树查询与后台科室新增、编辑、停用、删除")
@RestController
@RequestMapping("/api/admin/departments")
@RequiredArgsConstructor
public class AdminDepartmentController {

    private final AdminDepartmentService adminDepartmentService;

    @Operation(summary = "分页查询科室", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @GetMapping("/list")
    public ApiResponse<PageResult<Department>> list(
            @RequestParam(required = false) String name,
            @RequestParam(required = false) String departmentType,
            @RequestParam(required = false) Long parentId,
            @RequestParam(required = false) Boolean excludeRoot,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(adminDepartmentService.list(name, departmentType, parentId, excludeRoot, page, size));
    }

    @Operation(summary = "新增科室", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PostMapping
    public ApiResponse<Long> create(@Valid @RequestBody Department department) {
        return ApiResponse.success(adminDepartmentService.create(department));
    }

    @Operation(summary = "编辑科室", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}")
    public ApiResponse<Void> update(@PathVariable Long id, @RequestBody Department department) {
        adminDepartmentService.update(id, department);
        return ApiResponse.success();
    }

    @Operation(summary = "启用/停用科室", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}/status")
    public ApiResponse<Void> toggleStatus(@PathVariable Long id, @Valid @RequestBody ToggleStatusRequest request) {
        adminDepartmentService.toggleStatus(id, request.enabled());
        return ApiResponse.success();
    }

    @Operation(summary = "逻辑删除科室", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        adminDepartmentService.delete(id);
        return ApiResponse.success();
    }
}
