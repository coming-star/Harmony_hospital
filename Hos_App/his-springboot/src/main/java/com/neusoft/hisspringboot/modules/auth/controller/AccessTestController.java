package com.neusoft.hisspringboot.modules.auth.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.security.LoginUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 通用登录态接口：患者端与管理端共用。
 * 凭请求头中的 JWT 返回当前登录账号的用户ID、用户类型等信息。
 */
@Tag(name = "登录注册与认证鉴权", description = "患者注册/登录/登出、管理员登录/登出、查询当前登录用户")
@RestController
public class AccessTestController {

    /**
     * 查询当前登录用户：Token 有效时返回登录态中的用户信息。
     */
    @Operation(
            summary = "查询当前登录用户",
            description = "根据请求头中的 Token 返回当前登录账号信息（用户ID、用户类型 PATIENT/ADMIN）；需携带 Authorization: Bearer {token}",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/api/me")
    public ApiResponse<LoginUser> me(Authentication authentication) {
        return ApiResponse.success((LoginUser) authentication.getPrincipal());
    }
}
