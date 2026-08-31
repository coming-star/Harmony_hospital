package com.neusoft.hisspringboot.modules.auth.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neusoft.hisspringboot.modules.auth.dto.AdminLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.AppLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.AppRegisterRequest;
import com.neusoft.hisspringboot.modules.auth.dto.LoginResponse;
import com.neusoft.hisspringboot.modules.user.entity.SysUser;
import com.neusoft.hisspringboot.modules.user.mapper.SysUserMapper;
import com.neusoft.hisspringboot.security.JwtUtil;
import com.neusoft.hisspringboot.security.TokenBlacklistService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final SysUserMapper sysUserMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final TokenBlacklistService tokenBlacklistService;

    public void logout(String token) {
        JwtUtil.TokenMeta meta = jwtUtil.extractMeta(token);
        tokenBlacklistService.blacklist(meta.jti(), meta.expireAtEpochMillis());
    }

    public LoginResponse adminLogin(AdminLoginRequest request) {
        SysUser user = sysUserMapper.selectOne(
                new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getUsername, request.username())
                        .eq(SysUser::getUserType, "ADMIN")
                        .eq(SysUser::getStatus, 1)
        );

        return verifyPasswordAndCreateToken(user, request.password(), "管理员账号或密码错误");
    }

    public LoginResponse appLogin(AppLoginRequest request) {
        SysUser user = sysUserMapper.selectOne(
                new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getPhone, request.phone())
                        .eq(SysUser::getUserType, "PATIENT")
                        .eq(SysUser::getStatus, 1)
        );

        return verifyPasswordAndCreateToken(user, request.password(), "手机号或密码错误");
    }

    @Transactional
    public LoginResponse appRegister(AppRegisterRequest request) {
        Long count = sysUserMapper.selectCount(
                new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getPhone, request.phone())
        );

        if (count > 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "该手机号已注册");
        }

        SysUser user = new SysUser();
        user.setPhone(request.phone());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setNickname(request.nickname());
        user.setUserType("PATIENT");
        user.setStatus(1);
        user.setDeleted(0);

        sysUserMapper.insert(user);

        return createLoginResponse(user);
    }

    private LoginResponse verifyPasswordAndCreateToken(
            SysUser user,
            String rawPassword,
            String errorMessage
    ) {
        if (user == null || !passwordEncoder.matches(rawPassword, user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, errorMessage);
        }

        user.setLastLoginAt(LocalDateTime.now());
        sysUserMapper.updateById(user);

        return createLoginResponse(user);
    }

    private LoginResponse createLoginResponse(SysUser user) {
        return new LoginResponse(
                jwtUtil.createToken(user.getId(), user.getUserType()),
                "Bearer",
                user.getId(),
                user.getNickname(),
                user.getUserType()
        );
    }
}