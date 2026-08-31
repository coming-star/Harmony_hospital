package com.neusoft.hisspringboot.modules.auth.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.security.LoginUser;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.HttpHeaders;

@Tag(name = "认证权限验证", description = "JWT 与角色隔离测试接口")
@RestController
public class AccessTestController {

    @Operation(
            summary = "查询当前登录用户",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/api/me")
    public ApiResponse<LoginUser> me(Authentication authentication) {
        return ApiResponse.success((LoginUser) authentication.getPrincipal());
    }

    @Operation(
            summary = "验证管理员权限",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/api/admin/test")
    public ApiResponse<String> adminTest() {
        return ApiResponse.success("管理员权限验证通过");
    }

    @Operation(
            summary = "验证患者权限",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/api/app/test")
    public ApiResponse<String> appTest() {
        return ApiResponse.success("患者权限验证通过");
    }
}