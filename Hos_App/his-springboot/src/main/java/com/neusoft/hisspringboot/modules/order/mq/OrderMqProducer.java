package com.neusoft.hisspringboot.modules.order.mq;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.core.RocketMQTemplate;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * 订单相关 MQ 生产者，负责两类消息：
 * 1. 订单超时取消的"延迟消息"（替代原先每 60 秒的定时扫描）：
 *    下单成功后发一条延迟消息（只带 orderId），到期由 {@link OrderTimeoutConsumer} 校验并取消；
 *    RocketMQ 固定延迟档位没有 15 分钟这一档，因此采用"最大不超过剩余时间的档位 + 未到期续投"的方案，
 *    15 分钟订单实际投递路径为 10 分钟档 → 5 分钟档，到期后才会触发取消。
 * 2. 订单状态变更事件（order_event_topic）：供消息中心消费，生成站内信通知。
 *
 * 所有发送都做了 try-catch 兜底：RocketMQ 未启动时只打 warn 日志，订单主流程不受影响，
 * 超时取消由定时兜底任务（5 分钟一次）保证最终一定执行。
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class OrderMqProducer {

    /** 订单超时取消延迟消息主题 */
    public static final String TOPIC_ORDER_TIMEOUT = "order_timeout_topic";
    /** 订单状态变更事件主题（供消息中心消费，生成站内信） */
    public static final String TOPIC_ORDER_EVENT = "order_event_topic";
    /** 支付提醒延迟消息主题（下单 5 分钟未支付提醒用户尽快支付） */
    public static final String TOPIC_PAYMENT_REMINDER = "order_payment_reminder_topic";

    /** 延迟消息续投次数记录头（消费方读取后 +1 回传） */
    public static final String HEADER_HOP = "hop";

    /** RocketMQ 标准 18 档延迟级别对应的秒数：1s 5s 10s 30s 1m 2m 3m 4m 5m 6m 7m 8m 9m 10m 20m 30m 1h 2h */
    private static final long[] DELAY_LEVEL_SECONDS = {
            1, 5, 10, 30, 60, 120, 180, 240, 300, 360, 420, 480, 540, 600, 1200, 1800, 3600, 7200
    };

    private final RocketMQTemplate rocketMQTemplate;
    private final ObjectMapper objectMapper;

    /**
     * 下单成功后发送超时延迟消息：按"距过期还剩多久"选择延迟档位，
     * 消费时若仍未到期会续投，保证最终在过期之后送达并触发取消。
     */
    public void sendTimeoutDelayMessage(Long orderId, LocalDateTime expiredAt) {
        long remainingSeconds = Math.max(1, Duration.between(LocalDateTime.now(), expiredAt).getSeconds());
        sendDelayMessage(orderId, remainingSeconds, 1);
    }

    /** 消费方发现订单尚未到期时的续投入口 */
    public void resendTimeoutDelayMessage(Long orderId, long remainingSeconds, int hop) {
        sendDelayMessage(orderId, remainingSeconds, hop);
    }

    /**
     * 下单成功后发送一条 5 分钟延迟消息：到期时订单仍未支付则提醒用户尽快支付
     * （RocketMQ 标准 18 档里正好有 5 分钟档，无需续投）。发送失败不影响下单，
     * 提醒由 5 分钟定时兜底任务补发。
     */
    public void sendPaymentReminderDelayMessage(Long orderId) {
        try {
            // 第 9 档 = 5 分钟
            Message<String> message = MessageBuilder.withPayload(String.valueOf(orderId)).build();
            rocketMQTemplate.syncSend(TOPIC_PAYMENT_REMINDER, message, 3000, 9);
            log.info("已发送支付提醒延迟消息 orderId={}（5 分钟档）", orderId);
        } catch (Exception e) {
            log.warn("发送支付提醒延迟消息失败（不影响下单，将由定时兜底任务提醒） orderId={}", orderId, e);
        }
    }

    /**
     * 发布订单状态变更事件（支付成功 / 患者取消 / 管理员取消 / 超时取消）。
     * 失败不影响订单主流程；返回是否发送成功，调用方可据此做"直写站内信"兜底。
     */
    public boolean publishOrderEvent(OrderEventMessage event) {
        try {
            rocketMQTemplate.syncSend(TOPIC_ORDER_EVENT, objectMapper.writeValueAsString(event));
            log.info("已发布订单状态事件 type={} orderId={}", event.eventType(), event.orderId());
            return true;
        } catch (Exception e) {
            log.warn("发布订单状态事件失败（不影响订单主流程） type={} orderId={}",
                    event.eventType(), event.orderId(), e);
            return false;
        }
    }

    private void sendDelayMessage(Long orderId, long remainingSeconds, int hop) {
        int delayLevel = pickDelayLevel(remainingSeconds);
        try {
            Message<String> message = MessageBuilder.withPayload(String.valueOf(orderId))
                    .setHeader(HEADER_HOP, String.valueOf(hop))
                    .build();
            rocketMQTemplate.syncSend(TOPIC_ORDER_TIMEOUT, message, 3000, delayLevel);
            log.info("已发送订单超时延迟消息 orderId={} delayLevel={} (≈{}s) hop={}",
                    orderId, delayLevel, DELAY_LEVEL_SECONDS[delayLevel - 1], hop);
        } catch (Exception e) {
            // RocketMQ 未启动/发送失败：下单不受影响，超时取消交给定时兜底任务
            log.warn("发送订单超时延迟消息失败（不影响下单，将由定时兜底任务取消） orderId={}", orderId, e);
        }
    }

    /**
     * 从标准 18 档延迟级别里选"不超过剩余时间的最大一档"，返回档位序号（1-18）。
     * 例：剩余 15 分钟 → 10 分钟档（第 14 档）；剩余 4 分钟 → 3 分钟档（第 7 档）。
     * 消费端会再校验过期时间并对未到期的订单续投，因此最多晚一个档位送达，绝不提前。
     */
    static int pickDelayLevel(long remainingSeconds) {
        int chosen = 1;
        for (int i = 0; i < DELAY_LEVEL_SECONDS.length; i++) {
            if (DELAY_LEVEL_SECONDS[i] <= remainingSeconds) {
                chosen = i + 1;
            } else {
                break;
            }
        }
        return chosen;
    }
}
