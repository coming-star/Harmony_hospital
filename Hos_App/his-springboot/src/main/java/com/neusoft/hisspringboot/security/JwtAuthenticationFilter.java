package com.neusoft.hisspringboot.security;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final TokenBlacklistService tokenBlacklistService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        // 放行逻辑由 SecurityConfig.requestMatchers(...).permitAll() 统一配置，
        // 这里只负责：有 Authorization 头就解析 token，没有就交给 Spring Security 后面的 filter 链处理。
        String authorization = request.getHeader("Authorization");

        // 没有 token 或格式不对（必须是 "Bearer xxx.yyy.zzz"），放行让后续 filter 处理（未登录访问需认证接口会 403）
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            // 解析 token：验证签名 + 过期时间 + 提取 userId/userType/jti
            LoginUser loginUser = jwtUtil.parseToken(authorization.substring(7));

            // Redis 黑名单检查：已登出的 token 的 jti 会被拉黑，即使 token 未过期也拒绝访问
            // 异常时降级放行，避免 Redis 故障导致所有已认证请求 500
            try {
                if (tokenBlacklistService.isBlacklisted(loginUser.jti())) {
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.setContentType("application/json;charset=UTF-8");
                    response.getWriter().write(
                            "{\"code\":401,\"message\":\"Token已登出\",\"data\":null}"
                    );
                    return;
                }
            } catch (Exception e) {
                log.warn("Redis黑名单检查失败，降级放行: {}", e.getMessage());
            }

            // 认证通过：构造 Spring Security 的 Authentication 对象，注入安全上下文
            // 后续 Controller 里 @AuthenticationPrincipal LoginUser 就能拿到当前登录用户
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            loginUser,
                            null,
                            List.of(new SimpleGrantedAuthority("ROLE_" + loginUser.userType()))
                    );

            authentication.setDetails(
                    new WebAuthenticationDetailsSource().buildDetails(request)
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);
            filterChain.doFilter(request, response);
        } catch (JwtException | IllegalArgumentException exception) {
            // token 无效（签名不对/格式错误/已过期）→ 401
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(
                    "{\"code\":401,\"message\":\"Token无效或已过期\",\"data\":null}"
            );
        }
    }
}
