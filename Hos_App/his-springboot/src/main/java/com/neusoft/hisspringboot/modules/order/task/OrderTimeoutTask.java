package com.neusoft.hisspringboot.modules.order.task;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neusoft.hisspringboot.modules.order.entity.RegistrationOrder;
import com.neusoft.hisspringboot.modules.order.mapper.RegistrationOrderMapper;
import com.neusoft.hisspringboot.modules.order.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 15 分钟超时取消的临时实现：定时扫描替代 RocketMQ 延迟消息（docs/04 风险应对已认可此降级方案）。
 * 接入 RocketMQ 后应改为消费者调用 {@link OrderService#cancelByTimeout(Long)}，取消逻辑无需改动。
 */
@Component
@RequiredArgsConstructor
public class OrderTimeoutTask {

    private static final String STATUS_PENDING_PAYMENT = "PENDING_PAYMENT";

    private final RegistrationOrderMapper orderMapper;
    private final OrderService orderService;

    @Scheduled(fixedDelay = 60_000)
    public void cancelExpiredOrders() {
        List<RegistrationOrder> expired = orderMapper.selectList(
                new LambdaQueryWrapper<RegistrationOrder>()
                        .eq(RegistrationOrder::getStatus, STATUS_PENDING_PAYMENT)
                        .lt(RegistrationOrder::getExpiredAt, LocalDateTime.now())
        );

        for (RegistrationOrder order : expired) {
            orderService.cancelByTimeout(order.getId());
        }
    }
}
