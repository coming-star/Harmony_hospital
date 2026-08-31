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
    private String secret;

    @Value("${app.jwt.expire-hours}")
    private long expireHours;

    public String createToken(Long userId, String userType) {
        Date now = new Date();
        Date expireAt = new Date(now.getTime() + expireHours * 60 * 60 * 1000);

        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim("userType", userType)
                .issuedAt(now)
                .expiration(expireAt)
                .signWith(secretKey())
                .compact();
    }

    public LoginUser parseToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(secretKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return new LoginUser(
                Long.valueOf(claims.getSubject()),
                claims.get("userType", String.class)
        );
    }

    private SecretKey secretKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }
}