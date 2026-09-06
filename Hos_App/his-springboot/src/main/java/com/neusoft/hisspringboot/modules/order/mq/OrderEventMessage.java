package com.neusoft.hisspringboot.modules.order.mq;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * 订单状态变更事件：订单主流程在关键节点发布，消息中心（站内信）消费后给用户生成通知消息。
 * 通过 RocketMQ 异步解耦；事件只携带快照字段，消费方无需回查订单表，
 * 发送失败只打 warn 日志，绝不影响订单主流程。
 */
public record OrderEventMessage(
        String eventType,
        Long orderId,
        String orderNo,
        Long userId,
        String doctorName,
        String departmentName,
        String levelName,
        LocalDate visitDate,
        LocalTime startTime,
        Integer amountFen,
        LocalDateTime occurredAt
) {

    /** 事件类型：支付成功（预约成功） */
    public static final String EVENT_PAY_SUCCESS = "PAY_SUCCESS";
    /** 事件类型：患者主动取消 */
    public static final String EVENT_CANCEL_USER = "CANCEL_USER";
    /** 事件类型：管理员取消 */
    public static final String EVENT_CANCEL_ADMIN = "CANCEL_ADMIN";
    /** 事件类型：超时自动取消 */
    public static final String EVENT_CANCEL_TIMEOUT = "CANCEL_TIMEOUT";
}
