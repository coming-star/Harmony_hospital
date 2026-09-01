package com.neusoft.hisspringboot.modules.user.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.ToggleStatusRequest;
import com.neusoft.hisspringboot.modules.user.dto.AdminUserRequest;
import com.neusoft.hisspringboot.modules.user.dto.AdminUserResponse;
import com.neusoft.hisspringboot.modules.user.service.AdminUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

@Tag(name = "用户管理", description = "后台患者账号管理：新增、编辑、停用、删除")
@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final AdminUserService adminUserService;

    @Operation(summary = "分页查询用户", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @GetMapping("/list")
    public ApiResponse<PageResult<AdminUserResponse>> list(
            @RequestParam(required = false) String phone,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(adminUserService.list(phone, status, page, size));
    }

    @Operation(summary = "新增用户", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PostMapping
    public ApiResponse<Long> create(@Valid @RequestBody AdminUserRequest request) {
        return ApiResponse.success(adminUserService.create(request));
    }

    @Operation(summary = "编辑用户", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}")
    public ApiResponse<Void> update(@PathVariable Long id, @Valid @RequestBody AdminUserRequest request) {
        adminUserService.update(id, request);
        return ApiResponse.success();
    }

    @Operation(summary = "启用/停用用户", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}/status")
    public ApiResponse<Void> toggleStatus(@PathVariable Long id, @Valid @RequestBody ToggleStatusRequest request) {
        adminUserService.toggleStatus(id, request.enabled());
        return ApiResponse.success();
    }

    @Operation(summary = "逻辑删除用户", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        adminUserService.delete(id);
        return ApiResponse.success();
    }
}
