package com.neusoft.hisspringboot.modules.auth.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.user.dto.MeResponse;
import com.neusoft.hisspringboot.modules.user.dto.UpdateMeRequest;
import com.neusoft.hisspringboot.modules.user.entity.SysUser;
import com.neusoft.hisspringboot.modules.user.mapper.SysUserMapper;
import com.neusoft.hisspringboot.security.LoginUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

/**
 * 通用登录态接口：患者端与管理端共用。
 * 凭请求头中的 JWT 返回当前登录账号的用户ID、用户类型、昵称、头像等信息。
 */
@Tag(name = "登录注册与认证鉴权", description = "患者注册/登录/登出、管理员登录/登出、查询/修改当前登录用户")
@RestController
@RequiredArgsConstructor
public class AccessTestController {

    private final SysUserMapper sysUserMapper;

    /**
     * 查询当前登录用户：返回用户ID、类型、昵称、头像、手机号。
     */
    @Operation(
            summary = "查询当前登录用户",
            description = "根据请求头中的 Token 返回当前登录账号信息（用户ID、用户类型、昵称、头像、手机号）；需携带 Authorization: Bearer {token}",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/api/me")
    public ApiResponse<MeResponse> me(Authentication authentication) {
        LoginUser loginUser = (LoginUser) authentication.getPrincipal();
        SysUser user = sysUserMapper.selectById(loginUser.userId());
        if (user == null) {
            return ApiResponse.success(new MeResponse(loginUser.userId(), loginUser.userType(),
                    null, null, null));
        }
        return ApiResponse.success(new MeResponse(
                user.getId(),
                user.getUserType(),
                user.getNickname(),
                user.getAvatarUrl(),
                user.getPhone()
        ));
    }

    /**
     * 修改当前登录用户资料：昵称、头像。
     */
    @Operation(
            summary = "修改个人资料",
            description = "修改当前登录账号的昵称和头像（手机号/密码不在此处修改）；两个字段均可选，传哪个改哪个",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/api/me")
    public ApiResponse<MeResponse> updateMe(
            Authentication authentication,
            @Valid @RequestBody UpdateMeRequest request
    ) {
        LoginUser loginUser = (LoginUser) authentication.getPrincipal();
        SysUser user = sysUserMapper.selectById(loginUser.userId());
        if (user == null) {
            return ApiResponse.success(new MeResponse(loginUser.userId(), loginUser.userType(),
                    null, null, null));
        }
        if (request.nickname() != null) {
            user.setNickname(request.nickname().trim());
        }
        if (request.avatarUrl() != null) {
            user.setAvatarUrl(request.avatarUrl());
        }
        sysUserMapper.updateById(user);
        return ApiResponse.success(new MeResponse(
                user.getId(),
                user.getUserType(),
                user.getNickname(),
                user.getAvatarUrl(),
                user.getPhone()
        ));
    }
}
