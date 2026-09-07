package com.neusoft.hisspringboot.modules.auth.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.security.SecureRandom;
import java.time.Duration;

/**
 * 短信验证码服务（本地模拟）。
 * - 不接真实短信通道：验证码通过 log.info 打印到后端控制台，前端提示用户查看日志即可。
 * - Redis 存储：验证码 5 分钟有效；同一手机号同一用途 60 秒内只能发一次；每天每号码每用途最多 10 条。
 * - 校验失败 5 次后当前验证码作废，需重新获取。
 * Redis key 约定：his:sms:{用途}:{类型}:{手机号}。
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SmsCodeService {

    /** 验证码用途：短信登录（未注册自动注册） */
    public static final String SCENE_LOGIN = "LOGIN";
    /** 验证码用途：找回密码 */
    public static final String SCENE_RESET_PASSWORD = "RESET_PASSWORD";

    private static final String CODE_KEY = "his:sms:%s:code:%s";
    private static final String COOLDOWN_KEY = "his:sms:%s:cd:%s";
    private static final String DAILY_KEY = "his:sms:%s:daily:%s";
    private static final String FAIL_KEY = "his:sms:%s:fail:%s";

    private static final Duration CODE_TTL = Duration.ofMinutes(5);
    private static final Duration COOLDOWN_TTL = Duration.ofSeconds(60);
    private static final int DAILY_LIMIT = 10;
    private static final int MAX_FAIL_TIMES = 5;

    private final StringRedisTemplate redisTemplate;
    private final SecureRandom random = new SecureRandom();

    /**
     * 发送验证码（本地模拟：仅打印日志）。先做 60 秒冷却与每日上限双重限流。
     */
    public void sendCode(String phone, String scene) {
        // —— 第①层防刷：60 秒冷却，同一手机号同一用途 60 秒内只能发一次 ——
        String cooldownKey = String.format(COOLDOWN_KEY, scene, phone);
        if (Boolean.TRUE.equals(redisTemplate.hasKey(cooldownKey))) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "发送太频繁，请 60 秒后再试");
        }

        // —— 第②层防刷：每日上限，同一手机号同一用途每天最多 10 条 ——
        String dailyKey = String.format(DAILY_KEY, scene, phone);
        Long todayCount = redisTemplate.opsForValue().increment(dailyKey);
        if (todayCount != null && todayCount == 1) {
            redisTemplate.expire(dailyKey, Duration.ofDays(1)); // 首次计数设 1 天过期
        }
        if (todayCount != null && todayCount > DAILY_LIMIT) {
            throw new ResponseStatusException(HttpStatus.TOO_MANY_REQUESTS, "今日验证码发送次数已达上限，请明天再试");
        }

        // —— 生成 6 位随机验证码（SecureRandom 防可预测）——
        String code = String.format("%06d", random.nextInt(1_000_000));

        // —— 存 Redis：验证码 5 分钟有效 ——
        redisTemplate.opsForValue().set(String.format(CODE_KEY, scene, phone), code, CODE_TTL);
        // 写冷却标记（60 秒后自动过期）
        redisTemplate.opsForValue().set(cooldownKey, "1", COOLDOWN_TTL);
        // 清掉之前的失败计数（新验证码生效，旧失败计数无意义）
        redisTemplate.delete(String.format(FAIL_KEY, scene, phone));

        // 本地模拟短信通道：真实项目替换为阿里云/腾讯云短信 SDK 调用
        log.info("[短信模拟] scene={} phone={} 验证码：{}（5 分钟内有效）", scene, phone, code);
    }

    /**
     * 校验并消费验证码：正确则删除；错误则累计失败次数，超过 5 次作废。
     */
    public void verifyAndConsume(String phone, String scene, String code) {
        String codeKey = String.format(CODE_KEY, scene, phone);
        String saved = redisTemplate.opsForValue().get(codeKey);

        // 验证码不存在 = 已过期或从未发送
        if (saved == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "验证码已过期，请重新获取");
        }

        if (!saved.equals(code)) {
            // —— 第③层防刷：错误 5 次作废验证码 ——
            String failKey = String.format(FAIL_KEY, scene, phone);
            Long fails = redisTemplate.opsForValue().increment(failKey);
            if (fails != null && fails == 1) {
                redisTemplate.expire(failKey, CODE_TTL); // 失败计数 5 分钟后自动清零
            }
            if (fails != null && fails >= MAX_FAIL_TIMES) {
                // 错误满 5 次：删除验证码 + 失败计数，强制重新获取
                redisTemplate.delete(codeKey);
                redisTemplate.delete(failKey);
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "错误次数过多，验证码已作废，请重新获取");
            }
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "验证码错误");
        }

        // —— 验证通过：一次性消费（用完即删，防重放）——
        redisTemplate.delete(codeKey);
        redisTemplate.delete(String.format(FAIL_KEY, scene, phone));
    }
}
