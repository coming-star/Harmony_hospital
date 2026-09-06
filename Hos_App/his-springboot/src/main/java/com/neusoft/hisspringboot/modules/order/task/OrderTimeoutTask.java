package com.neusoft.hisspringboot.modules.order.task;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neusoft.hisspringboot.modules.notification.service.NotificationService;
import com.neusoft.hisspringboot.modules.order.entity.RegistrationOrder;
import com.neusoft.hisspringboot.modules.order.mapper.RegistrationOrderMapper;
import com.neusoft.hisspringboot.modules.order.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 15 分钟超时取消的定时兜底任务（主方案已改为 RocketMQ 延迟消息，见 OrderTimeoutConsumer）。
 * 兜底职责：
 * 1. RocketMQ 未启动/消息丢失/续投达上限等极端情况下，保证过期订单最终一定被取消；
 *    扫描频率从原来的 60 秒降为 5 分钟，正常情况下绝大多数订单由延迟消息提前取消。
 * 2. 5 分钟未支付提醒的兜底补发：MQ 未启动时下单发出的支付提醒延迟消息不会送达，
 *    由本任务扫描"下单满 5 分钟仍未支付"的订单补发提醒；dedup_key（PAYMENT_REMINDER:订单ID）
 *    唯一索引保证与 MQ 路径、多次扫描之间都不重复发送。
 */
@Component
@RequiredArgsConstructor
public class OrderTimeoutTask {

    private static final String STATUS_PENDING_PAYMENT = "PENDING_PAYMENT";

    private final RegistrationOrderMapper orderMapper;
    private final OrderService orderService;
    private final NotificationService notificationService;

    @Scheduled(fixedDelay = 300_000)
    public void cancelExpiredOrders() {
        List<RegistrationOrder> expired = orderMapper.selectList(
                new LambdaQueryWrapper<RegistrationOrder>()
                        .eq(RegistrationOrder::getStatus, STATUS_PENDING_PAYMENT)
                        .lt(RegistrationOrder::getExpiredAt, LocalDateTime.now())
        );

        for (RegistrationOrder order : expired) {
            orderService.cancelByTimeout(order.getId());
        }

        remindUnpaidOrders();
    }

    /** 5 分钟未支付提醒兜底：命中条件在 NotificationService.sendPaymentReminderIfFirst 内还会复查一遍 */
    private void remindUnpaidOrders() {
        LocalDateTime now = LocalDateTime.now();
        List<RegistrationOrder> remindable = orderMapper.selectList(
                new LambdaQueryWrapper<RegistrationOrder>()
                        .eq(RegistrationOrder::getStatus, STATUS_PENDING_PAYMENT)
                        .le(RegistrationOrder::getCreatedAt, now.minusMinutes(5))
                        .gt(RegistrationOrder::getExpiredAt, now)
        );

        for (RegistrationOrder order : remindable) {
            notificationService.sendPaymentReminderIfFirst(order);
        }
    }
}
