package com.neusoft.hisspringboot.modules.auth.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.auth.dto.AppLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.AppRegisterRequest;
import com.neusoft.hisspringboot.modules.auth.dto.LoginResponse;
import com.neusoft.hisspringboot.modules.auth.dto.SmsLoginRequest;
import com.neusoft.hisspringboot.modules.auth.dto.SmsResetPasswordRequest;
import com.neusoft.hisspringboot.modules.auth.dto.SmsSendRequest;
import com.neusoft.hisspringboot.modules.auth.service.AuthService;
import com.neusoft.hisspringboot.modules.auth.service.SmsCodeService;
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
 * 患者端注册登录接口。
 * 患者使用手机号注册、登录、登出；注册成功固定创建 PATIENT（患者）类型账号。
 */
@Tag(name = "登录注册与认证鉴权", description = "患者注册/登录/登出、管理员登录/登出、查询当前登录用户")
@RestController
@RequestMapping("/api/app/auth")
@RequiredArgsConstructor
public class AppAuthController {

    private final AuthService authService;
    private final SmsCodeService smsCodeService;

    /**
     * 患者注册：手机号 + 密码 + 昵称，注册成功直接返回登录 Token。
     */
    @Operation(summary = "患者注册", description = "手机号注册患者账号，注册成功后固定创建 PATIENT 账号并返回登录 Token")
    @PostMapping("/register")
    public ApiResponse<LoginResponse> register(
            @Valid @RequestBody AppRegisterRequest request
    ) {
        return ApiResponse.success(authService.appRegister(request));
    }

    /**
     * 患者登录：校验手机号与密码，成功后签发 JWT。
     */
    @Operation(summary = "患者登录", description = "患者使用手机号和密码登录，成功返回访问令牌 Token")
    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(
            @Valid @RequestBody AppLoginRequest request
    ) {
        return ApiResponse.success(authService.appLogin(request));
    }

    /**
     * 发送短信验证码（本地模拟）：验证码打印在后端控制台日志中。
     * scene=LOGIN 用于短信登录；scene=RESET_PASSWORD 用于找回密码。
     */
    @Operation(summary = "发送短信验证码",
            description = "本地模拟短信：验证码打印在后端控制台日志。60 秒内同号码同用途只能发一次，每天每号码每用途最多 10 条")
    @PostMapping("/sms/send")
    public ApiResponse<Void> sendSmsCode(
            @Valid @RequestBody SmsSendRequest request
    ) {
        smsCodeService.sendCode(request.phone(), request.scene());
        return ApiResponse.success();
    }

    /**
     * 短信验证码登录：校验验证码后登录；手机号未注册时自动创建患者账号。
     */
    @Operation(summary = "短信验证码登录",
            description = "校验短信验证码登录；手机号未注册时自动创建 PATIENT 账号（默认昵称“用户+手机号后4位”，初始密码需通过找回密码设置）")
    @PostMapping("/sms/login")
    public ApiResponse<LoginResponse> smsLogin(
            @Valid @RequestBody SmsLoginRequest request
    ) {
        return ApiResponse.success(authService.smsLogin(request));
    }

    /**
     * 短信验证码找回密码：校验验证码后为已注册患者账号设置新密码。
     */
    @Operation(summary = "短信验证码找回密码",
            description = "校验短信验证码（scene=RESET_PASSWORD）后重置该患者账号的登录密码")
    @PostMapping("/sms/reset-password")
    public ApiResponse<Void> smsResetPassword(
            @Valid @RequestBody SmsResetPasswordRequest request
    ) {
        authService.smsResetPassword(request);
        return ApiResponse.success();
    }

    /**
     * 患者登出：将当前 Token 加入 Redis 黑名单，到期前不可再使用。
     */
    @Operation(
            summary = "患者登出",
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
