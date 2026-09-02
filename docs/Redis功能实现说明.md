# Redis 功能实现说明

本项目使用 **Spring Boot 3 + Spring Data Redis + Lettuce 连接池**。
Redis 配置在 `application.yml` 中，默认地址 `localhost:6379`，密码 `123456`，database `0`。

所有 Redis key 统一前缀约定：

| 前缀 | 说明 |
|---|---|
| `his:cache:*` | 业务缓存（科室树、号源查询等），由 Spring Cache 统一管理 |
| `his:token:blacklist:*` | 登出 Token 黑名单 |
| `reg:lock:*` | 防重复挂号分布式锁 |
| `reg:limit:*` | 挂号接口限流计数器 |

---

## 一、给科室数据加缓存（Cache-Aside 旁路缓存）

### 解决什么问题
科室树（内科 → 心血管内科、神经内科...）基本不变，但每次患者打开预约页面、或管理端打开科室下拉时都要查数据库。查一次要 SQL + 内存构建树结构，数据多了浪费。

### 实现思路（4 步标准套路）
1. **读请求先查缓存** → 有就直接返回，不碰数据库
2. **缓存没有** → 查 MySQL，结果写回 Redis
3. **写请求（增/删/改/停用）** → 直接删除缓存，下次读自动回源
4. **TTL**：缓存 5 分钟自动过期（兜底机制，万一删除失败也不会一直脏读）

### 代码位置
**读缓存**：[DepartmentService.tree()](file:///d:/IDEA_Projects/test01/Hos_App/his-springboot/src/main/java/com/neusoft/hisspringboot/modules/department/service/DepartmentService.java)
```java
@Cacheable(value = "deptTree", key = "'all'", unless = "#result == null || #result.isEmpty()")
public List<DepartmentTreeNode> tree() {
    log.info("查询科室树（未命中缓存）"); // 第一次才打印
    // 查MySQL + 构树...
}
```
- `@Cacheable` 由 Spring Cache 自动处理，不手动 set/get
- 缓存 key：`his:cache:deptTree:all`（前缀 `his:cache:` + value `deptTree` + key `all`）
- TTL 5 分钟：在 [RedisConfig](file:///d:/IDEA_Projects/test01/Hos_App/his-springboot/src/main/java/com/neusoft/hisspringboot/config/RedisConfig.java) 的 `CacheManager` 统一配置

**写清缓存**：[AdminDepartmentService](file:///d:/IDEA_Projects/test01/Hos_App/his-springboot/src/main/java/com/neusoft/hisspringboot/modules/department/service/AdminDepartmentService.java)
```java
private static final String DEPT_TREE_CACHE_KEY = "his:cache:deptTree:all";
private final RedisCacheUtil redisCacheUtil;

private void evictDeptTreeCache() {
    redisCacheUtil.delete(DEPT_TREE_CACHE_KEY);
    log.info("已清除科室树缓存: {}", DEPT_TREE_CACHE_KEY);
}

// create() / update() / toggleStatus() / delete() 都调用
```

### 验证方法
```bash
# 1. 用 Apifox 调一次科室树接口（患者端或管理端触发均可）
# 2. redis-cli 查看：
KEYS his:cache:deptTree:*          # 应该看到 1 个 key
GET  his:cache:deptTree:all        # 返回 JSON 数组
TTL  his:cache:deptTree:all        # 剩余秒数（应在 0~300 之间）

# 3. 再调一次同样的接口：后端日志不打印 "查询科室树（未命中缓存）" = 命中了

# 4. 管理端停用一个科室：日志打印 "已清除科室树缓存"，再 KEYS 发现 key 消失了
```

---

## 二、用 Redis 锁防重复挂号（分布式锁）

### 解决什么问题
用户手快连点两下"挂号"按钮，或者用脚本同时发 2 条一模一样的请求，可能生成 2 笔订单、扣 2 次号源。数据库乐观锁（version）只防**扣号**那一步，防不住**重复下单**本身（2 次用不同 version 各扣一次就都成功了）。

### 实现思路（SETNX）
**SETNX = SET if Not eXists = `setIfAbsent`**：只有 key 不存在时才能设置成功。

把"同一个人抢同一段号"做成锁：
- **锁 key**：`reg:lock:{contactId}:{doctorId}:{visitDate}:{startTime-endTime}`
  例：`reg:lock:5001:3001:2026-09-03:08:00-09:00`
- **锁 value**：`UUID.randomUUID()`（释放锁时校验，避免误删别人的锁）
- **过期时间**：30 秒（如果执行业务的机器突然挂了，30 秒后锁自动释放，不会永远死锁）

```text
请求1: SETNX key=reg:lock:5001:3001... value=uuidA, 30s → 返回 true（抢到锁）
请求2: SETNX key=reg:lock:5001:3001... value=uuidB, 30s → 返回 false（没抢到）
                                                           ↑ 直接返回"请勿重复挂号"
请求1: 挂号完成 → finally { 校验 value==uuidA → DELETE key }（释放锁）
```

### 代码位置
[OrderService.createOrder()](file:///d:/IDEA_Projects/test01/Hos_App/his-springboot/src/main/java/com/neusoft/hisspringboot/modules/order/service/OrderService.java)
```java
// 1. 抢锁
String lockKey = REG_LOCK_PREFIX + contactId + ":" + doctorId + ":" + visitDate + ":" + startTime;
String lockValue = UUID.randomUUID().toString();
boolean locked = redisCacheUtil.setIfAbsent(lockKey, lockValue, 30);
if (!locked) throw new BusinessException("请勿重复挂号");

try {
    return doCreateOrder(userId, request); // 扣号源 + 生成订单 + 支付记录
} finally {
    // 2. 释放锁：只有自己加的锁才删
    String current = redisCacheUtil.get(lockKey);
    if (lockValue.equals(current)) redisCacheUtil.delete(lockKey);
}
```

### 关键细节（加分点）
- **`try-finally`**：无论业务成功还是抛异常，锁都一定会释放
- **释放前校验 value**：如果业务跑了 31 秒（超过锁 TTL），锁自动过期后可能被别人抢到并设了新的 value，这时候删就会把别人的锁误删掉。所以必须先 GET 一下值跟自己的 UUID 匹配才删
- **挂号结束清号源缓存**：扣完号以后号源剩余数量变了，缓存必须清掉，否则患者看到的剩余号数是旧的

### 验证方法
```bash
# 用 Apifox "快速连续发 2 条相同的挂号请求"（或并发按钮）：
# - 第 1 条成功，返回订单号
# - 第 2 条失败，提示 "请勿重复挂号"

# 同时 redis-cli 监控：
KEYS reg:lock:*       # 正在挂号瞬间会看到 1 个锁 key，约 30 秒内自动消失
```

---

## 三、给接口加限流（计数器方案）

### 解决什么问题
防止有人用脚本狂刷挂号接口打爆服务器，或者手抖连点 N 次。

### 实现思路（计数器：每分钟重置）
用 Redis 的 `INCR` 原子自增 + TTL 自动过期实现：

1. **限流 key**：`reg:limit:{userId}:{yyyyMMddHHmm}`
   例：`reg:limit:1001:202609021530` → 用户 1001 在 15:30 这一分钟的请求计数
2. **第 1 次调用**：`INCR` 返回 1，同时给 key 设 60 秒过期
3. **第 2~5 次调用**：`INCR` 返回 2~5，正常放行
4. **≥ 第 6 次调用**：`INCR` 返回 6，超过阈值 → 抛异常"操作过于频繁"
5. **下一分钟**：key 名变了（分钟后缀变了），计数器重置从 0 开始

```text
15:30:01 调用 → key=reg:limit:1001:202609021530 → INCR=1 → 放行
15:30:05 调用 → INCR=2 → 放行
...
15:30:29 调用 → INCR=5 → 放行
15:30:45 调用 → INCR=6 → 拒绝（超了）
15:31:00 调用 → key=reg:limit:1001:202609021531 → INCR=1 → 放行（新分钟重置）
```

### 代码位置
[OrderService.createOrder()](file:///d:/IDEA_Projects/test01/Hos_App/his-springboot/src/main/java/com/neusoft/hisspringboot/modules/order/service/OrderService.java)
```java
String minuteKey = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmm"));
String limitKey = REG_LIMIT_PREFIX + userId + ":" + minuteKey;
long count = redisCacheUtil.increment(limitKey, 60); // TTL 60s
if (count > 5) {
    throw new BusinessException("操作过于频繁，请 1 分钟后再试（每分钟最多 5 次）");
}
```

`RedisCacheUtil.increment()` 关键逻辑：
```java
public long increment(String key, long expireSeconds) {
    Long count = stringRedisTemplate.opsForValue().increment(key);
    if (count != null && count == 1) {
        stringRedisTemplate.expire(key, expireSeconds, TimeUnit.SECONDS);
    }
    return count != null ? count : 1L;
}
```
注意 `count==1` 时才设过期时间，只设一次。不然每次 INCR 都重新设 60 秒，计数器就永远不会过期了。

### 验证方法
```bash
# 同一个用户，Apifox 里狂点挂号按钮 10 次（注意不要点太快，避开锁的提示）：
# - 前 5 次正常
# - 第 6 次开始提示 "操作过于频繁，请 1 分钟后再试"
# - 等 1 分钟再点，又恢复正常

# redis-cli 监控：
KEYS reg:limit:*          # 每分钟会生成一个新的计数 key
GET  reg:limit:1001:xxxx  # 返回当前分钟累计请求数（字符串 "5"）
TTL  reg:limit:1001:xxxx  # 60 秒内递减到 -2（过期）
```

---

## 四、Token 黑名单（顺带实现）

### 作用
登出时把当前 token 的 jti 丢进 Redis 黑名单，TTL = token 剩余有效期。下次用这个 token 发请求时，校验黑名单 → 直接返回 401。

代码：[TokenBlacklistService](file:///d:/IDEA_Projects/test01/Hos_App/his-springboot/src/main/java/com/neusoft/hisspringboot/security/TokenBlacklistService.java)
```java
public void blacklist(String jti, long expireAtMillis) {
    long remaining = Math.max(expireAtMillis - now, 1000);
    redisTemplate.opsForValue().set("his:token:blacklist:" + jti, "1", remaining);
}
public boolean isBlacklisted(String jti) {
    return Boolean.TRUE.equals(redisTemplate.hasKey("his:token:blacklist:" + jti));
}
```

---

## 五、Redis 关键配置

**依赖**：`pom.xml`
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
```

**连接配置**：`application.yml`
```yaml
spring:
  data:
    redis:
      host: localhost
      port: 6379
      database: 0
      password: "123456"
      timeout: 5s
      lettuce:
        pool:
          max-active: 8
          max-idle: 8
  cache:
    type: redis
```

**统一序列化配置**：[RedisConfig](file:///d:/IDEA_Projects/test01/Hos_App/his-springboot/src/main/java/com/neusoft/hisspringboot/config/RedisConfig.java)
- RedisTemplate：key 用 String 序列化，value 用 GenericJackson2JsonRedisSerializer（存 JSON，跨语言可读）
- CacheManager：统一 TTL 5 分钟，key 前缀 `his:cache:{name}:`，空值不缓存

**工具类封装**：[RedisCacheUtil](file:///d:/IDEA_Projects/test01/Hos_App/his-springboot/src/main/java/com/neusoft/hisspringboot/common/RedisCacheUtil.java)
```java
set(key, value, expireSeconds)   // 写入
get(key)                          // 读取
delete(key)                       // 删除
setIfAbsent(key, val, seconds)    // 抢锁（SETNX）
increment(key, seconds)           // 计数（+1，首次自动设过期）
```

---

## 六、补充：Redis 锁 vs 幂等键 idempotencyKey（两个都不能删）

挂号请求的 JSON 里有一个 `idempotencyKey` 字段，也是用来防重复提交的。它和 Redis 锁虽然都跟"防重复"相关，但**解决的是两个完全不同维度的问题，互为补充，不能互相替代**。

### 6.1 幂等键 idempotencyKey 是什么

`CreateOrderRequest` 里的字段，由**前端生成唯一值**（推荐 UUID），传给后端。后端在创建订单之前先查库：

```java
RegistrationOrder existing = orderMapper.selectOne(
    new LambdaQueryWrapper<RegistrationOrder>()
        .eq(RegistrationOrder::getUserId, userId)
        .eq(RegistrationOrder::getIdempotencyKey, request.idempotencyKey())
);
if (existing != null) {
    return toDetail(existing); // 同一个 key 再次提交，直接返回已创建的订单
}
```

存在数据列：`registration_order.idempotency_key`。

### 6.2 两者对比

| 维度 | 幂等键 `idempotencyKey` | Redis 分布式锁 |
|---|---|---|
| **防的是什么** | **非并发的重试请求**（网络超时前端重试） | **同瞬间并发点击**（手快连点两下、脚本并发） |
| **工作方式** | 查 MySQL → 有就返回已有订单，不重复创建 | Redis `SETNX` 原子抢锁 → 同一维度同一时间只放行一个请求 |
| **触发条件** | 同一用户 + 同一个 key（隔几秒、几分钟都拦） | 同一 30s 内 + 同一就诊人/医生/日期/时段维度（过期自动失效） |
| **存储位置** | MySQL（持久化到数据库，永不消失） | Redis（临时 key，30s TTL） |
| **并发下能防吗** | ❌ 不能。两请求同时 `selectOne` 都查不到 → 都去创建订单 → 重复 | ✅ 能。SETNX 是原子操作，只有一个能抢到锁 |
| **重试下能防吗** | ✅ 能。同一个 key 查库一定查到，不管隔多久 | ❌ 不能。隔 10 秒锁已经释放了，拦不住 |

### 6.3 两个实际场景说明为什么都要留

#### 场景 1：网络超时重试（只有幂等键能防）
> 点挂号 → 后端扣号源 + 生成订单成功 → 响应返回时网络断了 → 前端没收到响应 → 15 秒后自动重试同样的请求（带同一个 `idempotencyKey`）
>
> - Redis 锁：锁 TTL 30s 可能还在也可能过了，就算还在 key 拼的是就诊人+医生+日期+时段，重试应该会被同一个锁拦住？但是如果 TTL 过了（比如重试发生在 31 秒后），锁就不管了。更关键的是：幂等键保证你即使过了 1 天再用同一个 key，也一定返回原始订单，绝不会重复创建。这个持久性是锁做不到的。
> - 幂等键：查数据库，有。直接返回历史订单。✅

#### 场景 2：同时点两下挂号（只有 Redis 锁能防）
> 用户手快连点挂号按钮，两条请求 1ms 内先后到达后端。两条请求**同时**执行 `selectOne(idempotencyKey)` → 都没查到 existing → 都去扣号源 + 插入订单 → 结果生成了两笔订单（扣两次号，同一段号被挂两次）。
>
> - 幂等键：先查后写有竞态窗口，拦不住。❌
> - Redis 锁：`SETNX` 是 Redis 单线程原子操作，一定只有一条请求抢到锁，另一条直接返回"请勿重复挂号"。✅

### 6.4 结论

两者是**双重防护、互补关系**。完整调用顺序就是现在代码里的样子：

```text
① 先限流（每分钟最多 5 次）
   ↓
② 再抢 Redis 锁（防止并发重复）
   ↓ try-finally { 释放锁 + 清号源缓存 }
   ③ 幂等键检查（防止重试重复，写进数据库永久保证）
      ↓
      ④ 扣号源 + 生成订单 + 支付记录
```

**建议都保留，不要删其中任意一个。**
