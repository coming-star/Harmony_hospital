package com.neusoft.hisspringboot.modules.order.mq;

import com.neusoft.hisspringboot.config.RocketMQAvailableCondition;
import com.neusoft.hisspringboot.modules.order.entity.RegistrationOrder;
import com.neusoft.hisspringboot.modules.order.mapper.RegistrationOrderMapper;
import com.neusoft.hisspringboot.modules.order.service.OrderService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.common.message.MessageExt;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.context.annotation.Conditional;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDateTime;

/**
 * 订单超时取消的延迟消息消费者（替代原先每 60 秒的定时扫描，扫描任务降为 5 分钟兜底）。
 *
 * 处理逻辑（幂等）：
 * 1. 订单不存在 / 已不是待支付状态 → 直接 ACK 跳过（已被支付或取消，取消逻辑本身幂等）；
 * 2. 已过期待支付时间 → 复用 {@link OrderService#cancelByTimeout(Long)} 取消（回补号源 + 清号源缓存）；
 * 3. 还没到期 → 按剩余时间续投一条新的延迟消息（RocketMQ 固定档位没有 15 分钟，
 *    15 分钟订单按 10 分钟 → 5 分钟两跳投递），最多续投 {@link #MAX_HOP} 次后交给兜底任务。
 *
 * 加 @Conditional：NameServer 不可达时不注册该消费者（否则其启动阶段连接失败会拖垮整个应用），
 * 超时取消完全交给定时兜底任务。
 */
@Component
@Conditional(RocketMQAvailableCondition.class)
@RequiredArgsConstructor
@Slf4j
@RocketMQMessageListener(
        topic = OrderMqProducer.TOPIC_ORDER_TIMEOUT,
        consumerGroup = "his_order_timeout_consumer_group",
        maxReconsumeTimes = 3
)
public class OrderTimeoutConsumer implements RocketMQListener<MessageExt> {

    private static final String STATUS_PENDING_PAYMENT = "PENDING_PAYMENT";
    /** 最大续投次数：15 分钟订单只需 2 跳，留足余量；超过则交给定时兜底任务 */
    private static final int MAX_HOP = 6;

    private final RegistrationOrderMapper orderMapper;
    private final OrderService orderService;
    private final OrderMqProducer orderMqProducer;

    @Override
    public void onMessage(MessageExt message) {
        String body = message.getBody() == null ? "" : new String(message.getBody(), StandardCharsets.UTF_8);
        Long orderId = parseOrderId(body);
        if (orderId == null) {
            log.warn("订单超时消息格式非法，跳过 body={}", body);
            return;
        }

        RegistrationOrder order = orderMapper.selectById(orderId);
        if (order == null) {
            log.warn("订单超时消息对应的订单不存在，跳过 orderId={}", orderId);
            return;
        }
        if (!STATUS_PENDING_PAYMENT.equals(order.getStatus())) {
            // 已支付/已取消：幂等跳过
            log.info("订单已非待支付状态，跳过超时取消 orderId={} status={}", orderId, order.getStatus());
            return;
        }

        long remainingSeconds = Duration.between(LocalDateTime.now(), order.getExpiredAt()).getSeconds();
        if (remainingSeconds <= 0) {
            orderService.cancelByTimeout(orderId);
            log.info("订单超时，已自动取消（回补号源） orderId={}", orderId);
            return;
        }

        int hop = parseHop(message.getUserProperty(OrderMqProducer.HEADER_HOP));
        if (hop >= MAX_HOP) {
            log.error("订单超时消息续投达上限仍未到期，交由定时兜底任务处理 orderId={} remaining={}s",
                    orderId, remainingSeconds);
            return;
        }
        orderMqProducer.resendTimeoutDelayMessage(orderId, remainingSeconds, hop + 1);
        log.info("订单尚未到期，已续投延迟消息 orderId={} remaining={}s hop={}", orderId, remainingSeconds, hop + 1);
    }

    private Long parseOrderId(String body) {
        try {
            return Long.parseLong(body.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private int parseHop(String hop) {
        try {
            return hop == null ? 0 : Integer.parseInt(hop);
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}
