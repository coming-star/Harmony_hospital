package com.neusoft.hisspringboot.modules.notification.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.notification.dto.MessageItem;
import com.neusoft.hisspringboot.modules.notification.entity.Message;
import com.neusoft.hisspringboot.modules.notification.mapper.MessageMapper;
import com.neusoft.hisspringboot.modules.order.entity.RegistrationOrder;
import com.neusoft.hisspringboot.modules.order.mq.OrderEventMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * 消息中心（站内信）服务：
 * 1. 消费订单状态事件（order_event_topic）生成站内信，dedup_key 唯一索引保证重复消费/重试不重发；
 *    MQ 不可用时由 OrderService 同步直写兜底（dedup_key 同样幂等）；
 * 2. 就诊提醒：就诊前 24 小时、3 小时各提醒一次，由 VisitReminderTask 每 10 分钟扫描触发；
 * 3. 支付提醒：下单 5 分钟未支付提醒尽快支付，由 5 分钟延迟消息/定时兜底任务触发（每单一次）；
 * 4. 患者端查询：未读数、分页列表、单条已读、全部已读。
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    /** 消息类型：预约成功 */
    public static final String TYPE_ORDER_PAY_SUCCESS = "ORDER_PAY_SUCCESS";
    /** 消息类型：订单已取消（患者/管理员） */
    public static final String TYPE_ORDER_CANCELLED = "ORDER_CANCELLED";
    /** 消息类型：订单超时自动取消 */
    public static final String TYPE_ORDER_TIMEOUT = "ORDER_TIMEOUT";
    /** 消息类型：就诊提醒 */
    public static final String TYPE_VISIT_REMINDER = "VISIT_REMINDER";
    /** 消息类型：支付提醒（下单 5 分钟未支付） */
    public static final String TYPE_PAYMENT_REMINDER = "PAYMENT_REMINDER";

    private static final String STATUS_PENDING_PAYMENT = "PENDING_PAYMENT";

    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm");

    private final MessageMapper messageMapper;

    /** 订单事件 → 站内信（幂等：dedup_key = "事件类型:订单ID"，重复消费直接跳过） */
    public void handleOrderEvent(OrderEventMessage event) {
        String when = (event.visitDate() == null ? "" : event.visitDate().toString())
                + " " + (event.startTime() == null ? "" : TIME_FMT.format(event.startTime()));
        String target = buildTarget(event);
        String fee = event.amountFen() == null
                ? ""
                : "，挂号费 " + BigDecimal.valueOf(event.amountFen(), 2).toPlainString() + " 元";

        String type;
        String title;
        String content;
        switch (event.eventType()) {
            case OrderEventMessage.EVENT_PAY_SUCCESS -> {
                type = TYPE_ORDER_PAY_SUCCESS;
                title = "预约成功";
                content = "您已成功预约 " + target + "，就诊时间 " + when + fee + "，请按时到院就诊。";
            }
            case OrderEventMessage.EVENT_CANCEL_USER -> {
                type = TYPE_ORDER_CANCELLED;
                title = "订单已取消";
                content = "您已取消预约 " + target + "，就诊时间 " + when + "，号源已释放。";
            }
            case OrderEventMessage.EVENT_CANCEL_ADMIN -> {
                type = TYPE_ORDER_CANCELLED;
                title = "订单已取消";
                content = "您的预约 " + target + "（就诊时间 " + when + "）已被医院管理员取消，如有疑问请联系医院。";
            }
            case OrderEventMessage.EVENT_CANCEL_TIMEOUT -> {
                type = TYPE_ORDER_TIMEOUT;
                title = "订单超时已取消";
                content = "您的挂号订单 " + target + "（就诊时间 " + when + "）因超过 15 分钟未支付已被自动取消，号源已释放。";
            }
            default -> {
                log.warn("未知的订单事件类型，跳过 type={} orderId={}", event.eventType(), event.orderId());
                return;
            }
        }

        insertMessage(event.userId(), type, title, content, event.orderId(),
                event.eventType() + ":" + event.orderId());
    }

    /**
     * 就诊提醒：就诊前 hoursAhead 小时（24 / 3）各提醒一次。
     * 判定"首次越过提醒时点"：剩余时间在 (0, hoursAhead] 内即尝试写入，
     * dedup_key = "订单ID:REMIND_24H/3H" 唯一索引保证同一订单同一时点只发一条。
     * 另外要求下单时间早于提醒时点：临期挂号（如提前 2 小时挂号）不补发"24 小时提醒"。
     */
    public void sendVisitReminderIfFirst(RegistrationOrder order, int hoursAhead) {
        LocalDateTime visitTime = LocalDateTime.of(order.getVisitDate(), order.getStartTime());
        long remainingMinutes = Duration.between(LocalDateTime.now(), visitTime).toMinutes();
        if (remainingMinutes <= 0 || remainingMinutes > hoursAhead * 60L) {
            return;
        }
        if (order.getCreatedAt() != null && order.getCreatedAt().isAfter(visitTime.minusHours(hoursAhead))) {
            return;
        }

        String when = order.getVisitDate() + " " + TIME_FMT.format(order.getStartTime());
        String target = String.join(" ",
                nonNull(order.getDepartmentNameSnapshot()),
                nonNull(order.getDoctorNameSnapshot()),
                nonNull(order.getLevelNameSnapshot())).trim();
        String lead = hoursAhead == 24 ? "明天" : "约 " + hoursAhead + " 小时后";
        String title = "就诊提醒";
        String content = "您 " + lead + "有一场预约：" + target + "，就诊时间 " + when
                + "，请提前到院取号就诊。";

        insertMessage(order.getUserId(), TYPE_VISIT_REMINDER, title, content, order.getId(),
                order.getId() + ":REMIND_" + hoursAhead + "H");
    }

    /**
     * 支付提醒：下单 5 分钟仍未支付的待支付订单，提醒用户尽快支付（每单只提醒一次）。
     * MQ 可用时由 5 分钟延迟消息（{@link com.neusoft.hisspringboot.modules.order.mq.OrderMqProducer}
     * 的 order_payment_reminder_topic）精准触发；MQ 不可用时由 5 分钟定时兜底任务扫描触发，
     * 两条路径都以 dedup_key = "PAYMENT_REMINDER:订单ID" 幂等去重。
     */
    public void sendPaymentReminderIfFirst(RegistrationOrder order) {
        if (!STATUS_PENDING_PAYMENT.equals(order.getStatus())) {
            return; // 已支付/已取消，无需提醒
        }
        LocalDateTime now = LocalDateTime.now();
        if (order.getExpiredAt() == null || !order.getExpiredAt().isAfter(now)) {
            return; // 已过支付期限，马上要被超时取消了，不再提醒
        }
        if (order.getCreatedAt() == null || order.getCreatedAt().isAfter(now.minusMinutes(5))) {
            return; // 下单还不到 5 分钟（兜底任务扫描窗口保护）
        }

        String target = String.join(" ",
                nonNull(order.getDepartmentNameSnapshot()),
                nonNull(order.getDoctorNameSnapshot()),
                nonNull(order.getLevelNameSnapshot())).trim();
        String fee = order.getAmountFen() == null
                ? ""
                : "，挂号费 " + BigDecimal.valueOf(order.getAmountFen(), 2).toPlainString() + " 元";
        String title = "请尽快完成支付";
        String content = "您的挂号订单 " + target + fee + " 已下单约 5 分钟仍未支付，请尽快完成支付；"
                + "超过 15 分钟未支付的订单将自动取消并释放号源。";

        insertMessage(order.getUserId(), TYPE_PAYMENT_REMINDER, title, content, order.getId(),
                "PAYMENT_REMINDER:" + order.getId());
    }

    /** 当前账号未读消息数（"我的"Tab 红点用） */
    public long unreadCount(Long userId) {
        return messageMapper.selectCount(new LambdaQueryWrapper<Message>()
                .eq(Message::getUserId, userId)
                .eq(Message::getIsRead, 0));
    }

    /** 站内信分页列表，按时间倒序 */
    public PageResult<MessageItem> list(Long userId, int page, int size) {
        Page<Message> mpPage = messageMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<Message>()
                        .eq(Message::getUserId, userId)
                        .orderByDesc(Message::getCreatedAt)
        );
        List<MessageItem> records = mpPage.getRecords().stream().map(this::toItem).toList();
        return PageResult.of(records, mpPage.getTotal(), page, size);
    }

    /** 标记单条已读（只能标记自己的消息） */
    public void markRead(Long userId, Long messageId) {
        messageMapper.update(null, new LambdaUpdateWrapper<Message>()
                .set(Message::getIsRead, 1)
                .eq(Message::getId, messageId)
                .eq(Message::getUserId, userId));
    }

    /** 全部标记已读 */
    public void markAllRead(Long userId) {
        messageMapper.update(null, new LambdaUpdateWrapper<Message>()
                .set(Message::getIsRead, 1)
                .eq(Message::getUserId, userId)
                .eq(Message::getIsRead, 0));
    }

    private void insertMessage(Long userId, String type, String title, String content, Long bizId, String dedupKey) {
        Message message = new Message();
        message.setUserId(userId);
        message.setType(type);
        message.setTitle(title);
        message.setContent(content);
        message.setBizId(bizId);
        message.setDedupKey(dedupKey);
        message.setIsRead(0);
        try {
            messageMapper.insert(message);
            log.info("已写入站内信 type={} userId={} bizId={} dedupKey={}", type, userId, bizId, dedupKey);
        } catch (DuplicateKeyException e) {
            // 同一订单同一事件/同一提醒时点已发过：幂等跳过
            log.info("站内信已存在，幂等跳过 dedupKey={}", dedupKey);
        }
    }

    private String buildTarget(OrderEventMessage event) {
        return String.join(" ",
                nonNull(event.departmentName()),
                nonNull(event.doctorName()),
                nonNull(event.levelName())).trim();
    }

    private String nonNull(String s) {
        return s == null ? "" : s;
    }

    private MessageItem toItem(Message message) {
        return new MessageItem(
                message.getId(),
                message.getType(),
                message.getTitle(),
                message.getContent(),
                message.getBizId(),
                message.getIsRead(),
                message.getCreatedAt()
        );
    }
}
