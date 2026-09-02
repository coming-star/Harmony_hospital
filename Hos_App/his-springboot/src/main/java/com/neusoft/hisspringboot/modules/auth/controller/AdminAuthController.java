package com.neusoft.hisspringboot.modules.auth.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.auth.dto.AdminLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.LoginResponse;
import com.neusoft.hisspringboot.modules.auth.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

/**
 * 管理端登录认证接口。
 * 仅 ADMIN（管理员）类型账号可以登录后台管理系统。
 */
@Tag(name = "登录注册与认证鉴权", description = "患者注册/登录/登出、管理员登录/登出、查询当前登录用户")
@RestController
@RequestMapping("/api/admin/auth")
@RequiredArgsConstructor
public class AdminAuthController {

    private final AuthService authService;

    /**
     * 管理员登录：用户名 + 密码，非 ADMIN 账号拒绝登录。
     */
    @Operation(summary = "管理员登录", description = "管理员使用用户名和密码登录后台，仅允许 userType 为 ADMIN 的账号登录")
    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(
            @Valid @RequestBody AdminLoginRequest request
    ) {
        return ApiResponse.success(authService.adminLogin(request));
    }

    /**
     * 管理员登出：将当前 Token 加入 Redis 黑名单，到期前不可再使用。
     */
    @Operation(
            summary = "管理员登出",
            description = "将当前 Token 加入黑名单，Token 到期前不可再使用；需在请求头携带 Authorization: Bearer {token}",
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
