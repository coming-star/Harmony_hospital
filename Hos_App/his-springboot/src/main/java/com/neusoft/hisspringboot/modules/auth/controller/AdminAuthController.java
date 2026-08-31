package com.neusoft.hisspringboot.modules.auth.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.auth.dto.AdminLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.LoginResponse;
import com.neusoft.hisspringboot.modules.auth.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@Tag(name = "管理员认证", description = "系统管理员后台登录接口")
@RestController
@RequestMapping("/api/admin/auth")
@RequiredArgsConstructor
public class AdminAuthController {

    private final AuthService authService;

    @Operation(summary = "管理员登录", description = "仅允许 userType 为 ADMIN 的账号登录后台")
    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(
            @Valid @RequestBody AdminLoginRequest request
    ) {
        return ApiResponse.success(authService.adminLogin(request));
    }
}