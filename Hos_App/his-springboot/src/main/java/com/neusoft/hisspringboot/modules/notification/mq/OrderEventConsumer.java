package com.neusoft.hisspringboot.modules.notification.mq;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.neusoft.hisspringboot.config.RocketMQAvailableCondition;
import com.neusoft.hisspringboot.modules.notification.service.NotificationService;
import com.neusoft.hisspringboot.modules.order.mq.OrderEventMessage;
import com.neusoft.hisspringboot.modules.order.mq.OrderMqProducer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.rocketmq.spring.annotation.RocketMQMessageListener;
import org.apache.rocketmq.spring.core.RocketMQListener;
import org.springframework.context.annotation.Conditional;
import org.springframework.stereotype.Component;

/**
 * 订单状态事件消费者：把订单关键节点（支付成功/患者取消/管理员取消/超时取消）
 * 转写成站内信写给下单用户（消息中心）。JSON 解析失败直接跳过（重试无意义）；
 * 写库失败向上抛出由 RocketMQ 按重试次数重投。
 *
 * 加 @Conditional：NameServer 不可达时不注册该消费者（否则其启动阶段连接失败会拖垮整个应用），
 * 应用照常启动，只是订单事件不再产生站内信。
 */
@Component
@Conditional(RocketMQAvailableCondition.class)
@RequiredArgsConstructor
@Slf4j
@RocketMQMessageListener(
        topic = OrderMqProducer.TOPIC_ORDER_EVENT,
        consumerGroup = "his_order_event_consumer_group",
        maxReconsumeTimes = 3
)
public class OrderEventConsumer implements RocketMQListener<String> {

    private final NotificationService notificationService;
    private final ObjectMapper objectMapper;

    @Override
    public void onMessage(String eventJson) {
        OrderEventMessage event;
        try {
            event = objectMapper.readValue(eventJson, OrderEventMessage.class);
        } catch (Exception e) {
            log.error("订单事件解析失败，跳过 eventJson={}", eventJson, e);
            return;
        }
        notificationService.handleOrderEvent(event);
    }
}
