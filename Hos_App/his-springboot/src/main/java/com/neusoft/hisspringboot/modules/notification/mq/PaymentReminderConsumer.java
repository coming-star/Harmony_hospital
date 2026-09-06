package com.neusoft.hisspringboot.modules.notification.mq;

import com.neusoft.hisspringboot.config.RocketMQAvailableCondition;
import com.neusoft.hisspringboot.modules.notification.service.NotificationService;
import com.neusoft.hisspringboot.modules.order.entity.RegistrationOrder;
import com.neusoft.hisspringboot.modules.order.mapper.RegistrationOrderMapper;
import com.neusoft.hisspringboot.modules.order.mq.OrderMqProducer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.context.annotation.Conditional;
import org.springframework.stereotype.Component;

/**
 * 支付提醒消费者：消费下单时发出的 5 分钟延迟消息（order_payment_reminder_topic），
 * 到期时订单仍未支付则写一条"请尽快完成支付"站内信（dedup_key 幂等，每单只提醒一次）。
 * 订单已被支付/取消/超时取消时静默跳过；订单不存在（异常数据）也跳过。
 *
 * 加 @Conditional：NameServer 不可达时不注册该消费者（否则其启动阶段连接失败会拖垮整个应用），
 * 提醒由 5 分钟定时兜底任务（OrderTimeoutTask）补发。
 */
@Component
@Conditional(RocketMQAvailableCondition.class)
@RequiredArgsConstructor
@Slf4j
@RocketMQMessageListener(
        topic = OrderMqProducer.TOPIC_PAYMENT_REMINDER,
        consumerGroup = "his_payment_reminder_consumer_group"
)
public class PaymentReminderConsumer implements RocketMQListener<String> {

    private final NotificationService notificationService;
    private final RegistrationOrderMapper orderMapper;

    @Override
    public void onMessage(String orderIdStr) {
        Long orderId;
        try {
            orderId = Long.parseLong(orderIdStr.trim());
        } catch (NumberFormatException e) {
            log.error("支付提醒消息 orderId 非法，跳过 payload={}", orderIdStr);
            return;
        }
        RegistrationOrder order = orderMapper.selectById(orderId);
        if (order == null) {
            log.warn("支付提醒消息对应订单不存在，跳过 orderId={}", orderId);
            return;
        }
        notificationService.sendPaymentReminderIfFirst(order);
    }
}
