package com.neusoft.hisspringboot.modules.auth.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neusoft.hisspringboot.modules.auth.dto.AdminLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.AppLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.AppRegisterRequest;
import com.neusoft.hisspringboot.modules.auth.dto.LoginResponse;
import com.neusoft.hisspringboot.modules.auth.dto.SmsLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.SmsResetPasswordRequest;
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
    private final SmsCodeService smsCodeService;

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

    /**
     * 短信验证码登录：校验验证码后按手机号查用户；未注册则自动创建患者账号（免密注册）。
     */
    @Transactional
    public LoginResponse smsLogin(SmsLoginRequest request) {
        smsCodeService.verifyAndConsume(request.phone(), SmsCodeService.SCENE_LOGIN, request.code());

        SysUser user = sysUserMapper.selectOne(
                new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getPhone, request.phone())
                        .eq(SysUser::getUserType, "PATIENT")
        );

        if (user == null) {
            user = new SysUser();
            user.setPhone(request.phone());
            // 短信登录未设置密码，置为不可用的随机哈希；用户可后续通过找回密码设置
            user.setPasswordHash(passwordEncoder.encode(java.util.UUID.randomUUID().toString()));
            user.setNickname("用户" + request.phone().substring(7));
            user.setUserType("PATIENT");
            user.setStatus(1);
            user.setDeleted(0);
            sysUserMapper.insert(user);
        }

        if (user.getStatus() == null || user.getStatus() != 1) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "账号已被停用，请联系管理员");
        }

        user.setLastLoginAt(LocalDateTime.now());
        sysUserMapper.updateById(user);

        return createLoginResponse(user);
    }

    /**
     * 短信验证码找回密码：校验验证码后重置密码；仅对已注册的患者账号生效。
     */
    @Transactional
    public void smsResetPassword(SmsResetPasswordRequest request) {
        smsCodeService.verifyAndConsume(request.phone(), SmsCodeService.SCENE_RESET_PASSWORD, request.code());

        SysUser user = sysUserMapper.selectOne(
                new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getPhone, request.phone())
                        .eq(SysUser::getUserType, "PATIENT")
        );

        if (user == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "该手机号尚未注册");
        }

        if (passwordEncoder.matches(request.newPassword(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "新密码不能与原密码相同");
        }

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        sysUserMapper.updateById(user);
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
                user.getPhone(),
                user.getUserType()
        );
    }
}