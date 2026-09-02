package com.neusoft.hisspringboot.security;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Component
@RequiredArgsConstructor
@Slf4j
public class TokenBlacklistService {

    private static final String KEY_PREFIX = "his:token:blacklist:";

    private final StringRedisTemplate redisTemplate;

    public void blacklist(String jti, long expireAtEpochMillis) {
        long now = System.currentTimeMillis();
        long remainingMillis = Math.max(expireAtEpochMillis - now, 1000);

        String key = KEY_PREFIX + jti;
        redisTemplate.opsForValue().set(key, "1", Duration.ofMillis(remainingMillis));
        log.info("Token已加入黑名单: jti={}, ttl={}s", jti, remainingMillis / 1000);
    }

    public boolean isBlacklisted(String jti) {
        return Boolean.TRUE.equals(redisTemplate.hasKey(KEY_PREFIX + jti));
    }
}
