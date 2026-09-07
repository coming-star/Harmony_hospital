package com.neusoft.hisspringboot.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtUtil {

    @Value("${app.jwt.secret}")
    private String secret;          // HMAC-SHA 签名密钥，配置在 application.yml

    @Value("${app.jwt.expire-hours}")
    private long expireHours;       // token 有效期（小时），配置在 application.yml

    /**
     * 生成 JWT：payload = { jti(唯一ID), subject(userId), claim(userType), 签发时间, 过期时间 }
     * 签名算法 = HS256（HMAC-SHA256），密钥从配置读取
     */
    public String createToken(Long userId, String userType) {
        Date now = new Date();
        Date expireAt = new Date(now.getTime() + expireHours * 60 * 60 * 1000);

        return Jwts.builder()
                .id(java.util.UUID.randomUUID().toString())   // jti：token 唯一标识，用于登出拉黑
                .subject(String.valueOf(userId))               // sub：用户 ID
                .claim("userType", userType)                  // 自定义声明：用户角色（PATIENT/ADMIN）
                .issuedAt(now)                                 // iat：签发时间
                .expiration(expireAt)                          // exp：过期时间
                .signWith(secretKey())                         // 用密钥签名，防篡改
                .compact();                                    // 拼成 xxx.yyy.zzz 三段式字符串
    }

    /**
     * 解析 JWT：验证签名 + 提取 payload，签名不匹配或已过期会抛 JwtException
     */
    public LoginUser parseToken(String token) {
        Claims claims = parseClaims(token);

        return new LoginUser(
                Long.valueOf(claims.getSubject()),              // userId
                claims.get("userType", String.class),           // userType
                claims.getId()                                  // jti（用于黑名单检查）
        );
    }

    /**
     * 供登出使用：取出 jti 与到期时间写入黑名单，无需还原完整 LoginUser。
     */
    public TokenMeta extractMeta(String token) {
        Claims claims = parseClaims(token);
        return new TokenMeta(claims.getId(), claims.getExpiration().getTime());
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(secretKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private SecretKey secretKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public record TokenMeta(String jti, long expireAtEpochMillis) {
    }
}