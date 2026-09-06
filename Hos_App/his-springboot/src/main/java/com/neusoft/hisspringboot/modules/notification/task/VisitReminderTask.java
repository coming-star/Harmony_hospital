package com.neusoft.hisspringboot.modules.notification.task;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neusoft.hisspringboot.modules.notification.service.NotificationService;
import com.neusoft.hisspringboot.modules.order.entity.RegistrationOrder;
import com.neusoft.hisspringboot.modules.order.mapper.RegistrationOrderMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;

/**
 * 就诊提醒定时任务：每 10 分钟扫描已支付订单，
 * 命中"就诊前 24 小时""就诊前 3 小时"两个时点的各发一条站内信提醒。
 * 防重依赖 NotificationService 里的 dedup_key 唯一索引（同一订单同一时点只发一条），
 * 扫描窗口略宽于 10 分钟也不会重复发送。
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class VisitReminderTask {

    private static final String STATUS_PAID = "PAID";

    private final RegistrationOrderMapper orderMapper;
    private final NotificationService notificationService;

    @Scheduled(fixedDelay = 600_000)
    public void remindUpcomingVisits() {
        LocalDate today = LocalDate.now();
        // 只需覆盖未来 48 小时内的就诊：24 小时与 3 小时两个提醒时点都落在这个窗口里
        List<RegistrationOrder> orders = orderMapper.selectList(
                new LambdaQueryWrapper<RegistrationOrder>()
                        .eq(RegistrationOrder::getStatus, STATUS_PAID)
                        .ge(RegistrationOrder::getVisitDate, today)
                        .le(RegistrationOrder::getVisitDate, today.plusDays(2))
        );

        for (RegistrationOrder order : orders) {
            notificationService.sendVisitReminderIfFirst(order, 24);
            notificationService.sendVisitReminderIfFirst(order, 3);
        }
    }
}
