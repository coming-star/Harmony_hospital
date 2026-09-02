package com.neusoft.hisspringboot.modules.user.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.ToggleStatusRequest;
import com.neusoft.hisspringboot.modules.user.dto.AdminUserRequest;
import com.neusoft.hisspringboot.modules.user.dto.AdminUserResponse;
import com.neusoft.hisspringboot.modules.user.service.AdminUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

/**
 * 管理端患者账号接口：用户分页查询、新增、编辑、启用/停用、逻辑删除。
 */
@Tag(name = "用户管理", description = "后台患者账号管理：新增、编辑、停用、删除")
@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final AdminUserService adminUserService;

    /**
     * 分页查询用户：支持手机号、状态筛选。
     */
    @Operation(
            summary = "分页查询用户",
            description = "患者账号列表，支持按手机号模糊搜索、按状态（1启用/0停用）筛选",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/list")
    public ApiResponse<PageResult<AdminUserResponse>> list(
            @Parameter(description = "手机号（模糊匹配）") @RequestParam(required = false) String phone,
            @Parameter(description = "账号状态：1 启用 / 0 停用") @RequestParam(required = false) Integer status,
            @Parameter(description = "页码，从 1 开始，默认 1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页条数，默认 10") @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(adminUserService.list(phone, status, page, size));
    }

    /**
     * 新增用户：创建患者账号。
     */
    @Operation(
            summary = "新增用户",
            description = "后台新增患者账号（手机号 + 昵称 + 密码）",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping
    public ApiResponse<Long> create(@Valid @RequestBody AdminUserRequest request) {
        return ApiResponse.success(adminUserService.create(request));
    }

    /**
     * 编辑用户：password 留空表示不修改密码。
     */
    @Operation(
            summary = "编辑用户",
            description = "修改昵称等信息；password 留空表示不修改密码",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}")
    public ApiResponse<Void> update(
            @Parameter(description = "用户ID", required = true) @PathVariable Long id,
            @Valid @RequestBody AdminUserRequest request
    ) {
        adminUserService.update(id, request);
        return ApiResponse.success();
    }

    /**
     * 启用/停用用户：停用后该账号无法登录。
     */
    @Operation(
            summary = "启用/停用用户",
            description = "请求体 {\"enabled\": 1} 启用、{\"enabled\": 0} 停用；停用后该账号无法登录",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}/status")
    public ApiResponse<Void> toggleStatus(
            @Parameter(description = "用户ID", required = true) @PathVariable Long id,
            @Valid @RequestBody ToggleStatusRequest request
    ) {
        adminUserService.toggleStatus(id, request.enabled());
        return ApiResponse.success();
    }

    /**
     * 逻辑删除用户。
     */
    @Operation(
            summary = "逻辑删除用户",
            description = "逻辑删除患者账号",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(
            @Parameter(description = "用户ID", required = true) @PathVariable Long id
    ) {
        adminUserService.delete(id);
        return ApiResponse.success();
    }
}
