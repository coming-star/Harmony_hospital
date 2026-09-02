package com.neusoft.hisspringboot.common;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.Set;
import java.util.concurrent.TimeUnit;

/**
 * Redis 缓存与锁工具类：统一封装常见 set/get/del/setIfAbsent/increment 操作。
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RedisCacheUtil {

    private final StringRedisTemplate stringRedisTemplate;

    /** 写入缓存（带过期时间，秒） */
    public void set(String key, String value, long expireSeconds) {
        stringRedisTemplate.opsForValue().set(key, value, expireSeconds, TimeUnit.SECONDS);
    }

    /** 读取缓存 */
    public String get(String key) {
        return stringRedisTemplate.opsForValue().get(key);
    }

    /** 删除缓存 */
    public void delete(String key) {
        stringRedisTemplate.delete(key);
    }

    /**
     * 分布式锁：setIfAbsent（SETNX），不存在才设值。
     * @return true=抢到锁, false=没抢到
     */
    public boolean setIfAbsent(String key, String value, long expireSeconds) {
        Boolean ok = stringRedisTemplate.opsForValue()
                .setIfAbsent(key, value, expireSeconds, TimeUnit.SECONDS);
        return Boolean.TRUE.equals(ok);
    }

    /** 计数器自增（首次会自动设过期时间，秒），返回自增后的值 */
    public long increment(String key, long expireSeconds) {
        Long count = stringRedisTemplate.opsForValue().increment(key);
        if (count != null && count == 1) {
            stringRedisTemplate.expire(key, expireSeconds, TimeUnit.SECONDS);
        }
        return count != null ? count : 1L;
    }

    /**
     * 按前缀模糊删除所有匹配 key。
     * 示例：deleteByPrefix("his:cache:slotQuery:2001_2026-09-02_")
     * 会把该科室该日期下 "_all"、带具体 levelId 的所有号源缓存全部清掉。
     * 生产环境千万不要用 keys("*") 这种极宽的前缀，会阻塞 Redis；这里都是窄范围（精确到科室+日期前缀）。
     */
    public void deleteByPrefix(String prefix) {
        Set<String> keys = stringRedisTemplate.keys(prefix + "*");
        if (keys != null && !keys.isEmpty()) {
            stringRedisTemplate.delete(keys);
            log.info("Redis 按前缀删除 {} 条 key, 前缀={}", keys.size(), prefix);
        }
    }
}
