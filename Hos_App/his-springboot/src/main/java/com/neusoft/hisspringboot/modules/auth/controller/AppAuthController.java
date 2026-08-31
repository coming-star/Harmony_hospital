package com.neusoft.hisspringboot.modules.auth.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.auth.dto.AppLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.AppRegisterRequest;
import com.neusoft.hisspringboot.modules.auth.dto.LoginResponse;
import com.neusoft.hisspringboot.modules.auth.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@Tag(name = "患者认证", description = "鸿蒙 App 患者注册与登录接口")
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
}