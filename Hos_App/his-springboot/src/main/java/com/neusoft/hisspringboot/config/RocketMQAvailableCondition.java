package com.neusoft.hisspringboot.config;

import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.core.type.AnnotatedTypeMetadata;

import java.net.InetSocketAddress;
import java.net.Socket;

/**
 * RocketMQ NameServer 可达性探测条件。
 *
 * 背景：RocketMQ 消费者容器（@RocketMQMessageListener）在启动阶段就会连接 NameServer
 * 拉取 topic 路由，NameServer 未启动时会抛 RemotingConnectException 直接导致整个应用启动失败。
 *
 * 本条件在 Bean 注册阶段按 rocketmq.name-server 配置逐个尝试 TCP 连接（800ms 超时）：
 * - 至少一个地址可达 → 注册消费者，走 RocketMQ 延迟消息 + 事件消息链路；
 * - 全部不可达 → 跳过消费者注册，应用照常启动，超时取消由 5 分钟定时兜底任务保证，
 *   订单事件不再写站内信（与文档《06-RocketMQ订单超时与事件说明》的双通道设计一致）。
 *
 * 生产者（RocketMQTemplate）无需此条件：发送阶段才连接且已有 try-catch 兜底。
 */
public class RocketMQAvailableCondition implements Condition {

    private static final int CONNECT_TIMEOUT_MILLIS = 800;

    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        String nameServer = context.getEnvironment().getProperty("rocketmq.name-server");
        if (nameServer == null || nameServer.isBlank()) {
            return false;
        }
        for (String addr : nameServer.split(",")) {
            String[] hostPort = addr.trim().split(":");
            if (hostPort.length != 2) {
                continue;
            }
            try (Socket socket = new Socket()) {
                socket.connect(
                        new InetSocketAddress(hostPort[0], Integer.parseInt(hostPort[1])),
                        CONNECT_TIMEOUT_MILLIS);
                return true;
            } catch (Exception ignored) {
                // 该地址不可达，继续探测下一个
            }
        }
        return false;
    }
}
