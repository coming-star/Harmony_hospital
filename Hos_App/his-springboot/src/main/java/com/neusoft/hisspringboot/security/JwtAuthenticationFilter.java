package com.neusoft.hisspringboot.security;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
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
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final TokenBlacklistService tokenBlacklistService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        // ============【新增：静态资源、登录接口、文档放行】============
        String uri = request.getRequestURI();
        if (uri.startsWith("/index.html")
                || uri.startsWith("/js/")
                || uri.startsWith("/css/")
                || uri.startsWith("/img/")
                || uri.startsWith("/favicon.ico")
                || uri.startsWith("/doc.html")
                || uri.startsWith("/webjars/")
                || uri.startsWith("/v3/api-docs")
                || uri.startsWith("/swagger-resources")
                || uri.startsWith("/api/admin/auth/login")
                || uri.startsWith("/api/app/auth/login")
                || uri.startsWith("/api/app/auth/register")
                || uri.startsWith("/error")) {
            filterChain.doFilter(request, response);
            return;
        }
        // ==========================================================

        String authorization = request.getHeader("Authorization");

        if (authorization == null || !authorization.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            LoginUser loginUser = jwtUtil.parseToken(authorization.substring(7));

            if (tokenBlacklistService.isBlacklisted(loginUser.jti())) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write(
                        "{\"code\":401,\"message\":\"Token已登出\",\"data\":null}"
                );
                return;
            }

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
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(
                    "{\"code\":401,\"message\":\"Token无效或已过期\",\"data\":null}"
            );
        }
    }
}
