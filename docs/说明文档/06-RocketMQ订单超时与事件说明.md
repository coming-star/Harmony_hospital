# 06 · RocketMQ 订单超时与事件说明

> 更新日期：2026-09-06 ｜ 适用版本：RocketMQ 5.3.0 + rocketmq-spring-boot-starter 2.3.3（Spring Boot 3 兼容）

本文说明挂号模块引入 RocketMQ 后的三条消息链路：**订单超时取消（延迟消息）**、**订单状态事件（站内信）** 与 **5 分钟未支付提醒（延迟消息）**，并附 Windows 本地安装与验证步骤。

***

## 1. 为什么要引入 RocketMQ

| 原方案 | 问题 | 现方案 |
| --- | --- | --- |
| `@Scheduled` 定时任务每 60 秒扫描过期待支付订单 | 最长 60 秒延迟；扫描空转浪费 | 下单成功发**延迟消息**，到期精准投递触发取消 |
| 订单状态变更（支付成功/取消/超时）无事件 | 患者只能主动刷新才能感知 | 订单状态变更发布**事件消息**，消息中心消费后落库站内信 |
| 下单后一直不支付无任何提醒 | 患者容易忘记支付导致号源被超时释放 | 下单成功同时发 **5 分钟延迟消息**，到期仍未支付则推「请尽快完成支付」站内信 |

**兜底设计**：RocketMQ 未启动/发送失败只打 warn 日志，订单主流程不受影响；定时兜底任务降频为 **5 分钟一次**继续扫描（超时取消 + 未支付提醒），订单事件在 MQ 不可用时由 `publishEventWithFallback` **直接落库站内信**，双通道保证超时取消与消息通知最终一定执行。

***

## 2. Windows 本地安装 RocketMQ 5.3.0

### 2.1 下载与解压

1. 下载 Binary 包：https://rocketmq.apache.org/download → `rocketmq-all-5.3.0-bin-release.zip`
2. 解压到无空格路径，例如 `D:\rocketmq-5.3.0`

### 2.2 环境变量（系统变量）

| 变量名 | 值 |
| --- | --- |
| `ROCKETMQ_HOME` | `D:\rocketmq-5.3.0` |
| `NAMESRV_ADDR` | `localhost:9876` |

> 若内存有限，先编辑 `bin\runserver.cmd` 与 `bin\runbroker.cmd`，把 JVM `-Xms/-Xmx/-Xmn` 调小（如 512m/512m/256m），否则默认配置启动会占 4G+ 内存。

### 2.3 启动（按顺序开两个 cmd 窗口）

```bat
:: 窗口 1：NameServer
cd /d D:\rocketmq-5.3.0\bin
start mqnamesrv.cmd

:: 窗口 2：Broker（等 NameServer 打印 success 后再执行）
cd /d D:\rocketmq-5.3.0\bin
start mqbroker.cmd -n localhost:9876 autoCreateTopicEnable=true
```

### 2.4 验证

```bat
:: 查看集群状态（需 JAVA_HOME 已配置）
cd /d D:\rocketmq-5.3.0\bin
mqadmin clusterList -n localhost:9876
```

能看到 broker 地址（`127.0.0.1:10911`）即部署成功。停止顺序：先 `mqshutdown broker`（Windows 直接关窗口），再关 NameServer 窗口。

***

## 3. 后端配置

`application.yml`（已配置好，无需修改；`ROCKETMQ_NAME_SERVER` 环境变量优先）：

```yaml
rocketmq:
  name-server: ${ROCKETMQ_NAME_SERVER:localhost:9876}
  producer:
    group: his_order_producer_group
    send-message-timeout: 3000
    retry-times-when-send-failed: 2
```

**NameServer 未启动时应用仍可正常启动运行**，无需任何手动开关：
- 生产者：所有发送均 try-catch 兜底，失败只打 warn 日志；
- 消费者：通过 `RocketMQAvailableCondition`（config 包）在启动时探测 NameServer 端口（800ms 超时），**可达才注册消费者**；不可达则跳过消费者注册——否则消费者容器启动阶段会因连不上 NameServer 抛 RemotingConnectException 拖垮整个应用；
- 不可达时的效果：超时取消完全由定时兜底任务（5 分钟）执行，订单事件不再产生站内信，其余功能不受影响。

***

## 4. 消息链路一：订单超时取消（延迟消息）

### 4.1 流程

```
下单成功（PENDING_PAYMENT，expired_at = 下单+15min）
        │
        ▼
OrderMqProducer.sendTimeoutDelayMessage(orderId, expiredAt)
   按"距过期剩余时间"选 18 档延迟级别中 ≤ 剩余时间的最大档
        │
        ▼
order_timeout_topic（延迟投递）
        │
        ▼
OrderTimeoutConsumer.onMessage()
   ├─ 订单不存在 / 已非待支付 → 幂等跳过（ACK）
   ├─ 已过 expired_at → OrderService.cancelByTimeout(orderId)（取消+回补号源+清缓存）
   └─ 未到期 → 续投新的延迟消息（hop+1，最多 6 跳，超出交给定时兜底任务）
```

### 4.2 为什么没有 15 分钟档

RocketMQ 4.x/5.x 开源版固定 18 档延迟（1s 5s 10s 30s 1m 2m 3m 4m 5m 6m 7m 8m 9m 10m 20m 30m 1h 2h），**没有 15 分钟**。本方案采用「选不超过剩余时间的最大档 + 消费端未到期续投」：

- 剩余 15 分钟 → 先投 **10 分钟档** → 到期检查发现还剩 5 分钟 → 续投 **5 分钟档** → 到期取消；
- 绝不提前取消（消费端严格比对 `expired_at`），最多晚一个档位送达；
- `hop` 头记录续投次数，超过 `MAX_HOP=6` 放弃投递，交给定时兜底任务。

### 4.3 幂等与并发安全

- 消费端先查订单状态，非 `PENDING_PAYMENT` 直接跳过 → 消息重复投递无副作用；
- 真正的取消动作复用 `OrderService.cancelByTimeout`，内部状态机条件更新（乐观锁），与用户主动取消、管理员取消并发安全；
- 定时兜底任务（5 分钟）与延迟消息可能同时命中同一订单，同样被状态机挡掉，只会取消一次。

***

## 5. 消息链路二：订单状态事件 → 站内信

### 5.1 流程

```
订单关键节点：PAY_SUCCESS / PATIENT_CANCEL / ADMIN_CANCEL / TIMEOUT_CANCEL
        │
        ▼
OrderMqProducer.publishOrderEvent(OrderEventMessage)   → order_event_topic
        │
        ▼
OrderEventConsumer.onMessage()
   ├─ JSON 解析失败 → 记 error 跳过（重试无意义）
   └─ NotificationService.handleOrderEvent(event)
         组装标题/正文 → 写 message 表（dedup_key 唯一键防重）
```

- `dedup_key` 规则：订单事件为 `事件类型:订单ID`（如 `PAY_SUCCESS:2095770973474160642`），就诊提醒为 `订单ID:REMIND_24H/REMIND_3H`；
- 数据库唯一索引 `uk_message_dedup` 保证同一事件重复消费也只落一条站内信（幂等）；
- 写库失败向上抛出 → RocketMQ 按 `maxReconsumeTimes=3` 重投；
- 就诊前 24h/3h 提醒由 `VisitReminderTask` 定时任务直接落库，同样走 `dedup_key` 防重。

### 5.2 消息类型与站内信对照

| eventType | message.type | 站内信标题示例 |
| --- | --- | --- |
| PAY_SUCCESS | ORDER_PAY_SUCCESS | 预约成功 |
| PATIENT_CANCEL | ORDER_CANCELLED | 订单已取消 |
| ADMIN_CANCEL | ORDER_CANCELLED | 订单已取消 |
| TIMEOUT_CANCEL | ORDER_TIMEOUT | 订单超时未支付已自动取消 |

> 就诊提醒（`VISIT_REMINDER`，24h/3h）与未支付提醒（`PAYMENT_REMINDER`，下单 5 分钟未支付）由对应链路直接落库，不经过 `order_event_topic`，消息类型对照见链路三。

***

## 6. 消息链路三：5 分钟未支付提醒（延迟消息）

### 6.1 流程

```
下单成功（PENDING_PAYMENT）
        │
        ▼
OrderMqProducer.sendPaymentReminderDelayMessage(orderId)
   固定 9 号延迟档 = 5 分钟
        │
        ▼
order_payment_reminder_topic（延迟投递）
        │
        ▼
PaymentReminderConsumer.onMessage()
   └─ NotificationService.sendPaymentReminderIfFirst(order)
         ├─ 订单已非 PENDING_PAYMENT → 幂等跳过（已支付/已取消不再提醒）
         ├─ 下单不足 5 分钟 → 跳过
         └─ 组装"请尽快完成支付"站内信 → 写 message 表
              dedup_key = PAYMENT_REMINDER:{orderId}（同订单只提醒一次）
```

### 6.2 幂等与兜底

- `dedup_key = PAYMENT_REMINDER:订单ID`，数据库唯一索引保证同一订单最多一条未支付提醒；
- 消费端再次校验订单状态与下单时间，重复投递/迟到投递均无副作用；
- **MQ 不可用兜底**：定时任务 `OrderTimeoutTask.remindUnpaidOrders()`（5 分钟一轮）扫描「待支付且下单已超 5 分钟」的订单，直接调用 `sendPaymentReminderIfFirst` 落库，与延迟消息链路共用同一 `dedup_key`，不会重复提醒。

### 6.3 站内信类型对照（补充）

| message.type | 触发时机 | dedup_key |
| --- | --- | --- |
| VISIT_REMINDER | 就诊前 24h / 3h（VisitReminderTask） | `{orderId}:REMIND_24H` / `{orderId}:REMIND_3H` |
| PAYMENT_REMINDER | 下单 5 分钟仍未支付 | `PAYMENT_REMINDER:{orderId}` |

***

## 7. 验证步骤（启动 RocketMQ 后）

1. 启动后端，观察日志无 `rocketmq` 相关 warn；
2. 创建一笔订单不支付 → 日志出现 `已发送订单超时延迟消息 orderId=… delayLevel=…` 与 `已发送支付提醒延迟消息 orderId=…`；
3. 把这笔订单挂着不支付 15 分钟（测试可临时把 expiredAt 缩短）→ 日志依次出现 `已发送…delayLevel=14` → `已发送…delayLevel=9` → `订单超时，已自动取消（回补号源）`；
4. 支付一笔订单 → 日志出现 `已发布订单状态事件 type=PAY_SUCCESS`，App 消息中心（我的 → 消息）出现"预约成功"站内信，红点数 +1；
5. 创建订单后 5 分钟内不支付 → 消息中心出现"请尽快完成支付"提醒（`PAYMENT_REMINDER`）；此时再支付/取消，同订单不会出现第二条提醒；
6. 关闭 RocketMQ 再重复第 2 步 → 只出现 warn 日志，订单照常创建；超时取消与未支付提醒由定时兜底任务（5 分钟）执行；支付/取消订单 → 消息中心仍会出现对应站内信（`publishEventWithFallback` 直接落库）。
