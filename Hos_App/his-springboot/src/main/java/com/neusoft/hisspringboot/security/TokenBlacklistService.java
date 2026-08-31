package com.neusoft.hisspringboot.security;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 登出 Token 黑名单，基于 JVM 内存实现，仅适用于单实例本地开发/演示环境。
 * 后续多实例部署应迁移至 Redis（key 为 jti，value 为过期时间，TTL 与 Token 剩余有效期一致）。
 */
@Component
public class TokenBlacklistService {

    private final Map<String, Long> blacklist = new ConcurrentHashMap<>();

    public void blacklist(String jti, long expireAtEpochMillis) {
        blacklist.put(jti, expireAtEpochMillis);
    }

    public boolean isBlacklisted(String jti) {
        Long expireAt = blacklist.get(jti);

        if (expireAt == null) {
            return false;
        }

        if (expireAt < System.currentTimeMillis()) {
            blacklist.remove(jti);
            return false;
        }

        return true;
    }
}
