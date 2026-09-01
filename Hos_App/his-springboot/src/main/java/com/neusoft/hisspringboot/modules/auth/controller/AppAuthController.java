package com.neusoft.hisspringboot.modules.auth.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.auth.dto.AppLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.AppRegisterRequest;
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
@RequestMapping("/api/app/auth")
@RequiredArgsConstructor
public class AppAuthController {

    private final AuthService authService;

    @Operation(summary = "患者注册", description = "注册成功后固定创建 PATIENT 账号")
    @PostMapping("/register")
    public ApiResponse<LoginResponse> register(
            @Valid @RequestBody AppRegisterRequest request
    ) {
        return ApiResponse.success(authService.appRegister(request));
    }

    @Operation(summary = "患者登录", description = "患者使用手机号和密码登录")
    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(
            @Valid @RequestBody AppLoginRequest request
    ) {
        return ApiResponse.success(authService.appLogin(request));
    }

    @Operation(
            summary = "患者登出",
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