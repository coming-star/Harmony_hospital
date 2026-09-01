package com.neusoft.hisspringboot.modules.auth.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.auth.dto.AdminLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.LoginResponse;
import com.neusoft.hisspringboot.modules.auth.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

@Tag(name = "登录注册与认证鉴权", description = "患者/管理员注册登录登出、当前用户信息、角色权限验证")
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

    @Operation(
            summary = "管理员登出",
            description = "将当前 Token 加入黑名单，Token 到期前不可再使用",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping("/logout")
    public ApiResponse<Void> logout(HttpServletRequest request) {
        authService.logout(extractBearerToken(request));
        return ApiResponse.success();
    }

    private String extractBearerToken(HttpServletRequest request) {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);

        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "请先登录或 Token 已失效");
        }

        return authorization.substring(7);
    }
}