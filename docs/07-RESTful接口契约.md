# RESTful 接口契约

> 负责人：成员 A（组长·流程与契约） | 日期：2026-08-31
> 依据：`docs/03-技术方案与数据设计.md` §4 REST 接口边界、`docs/06-挂号流程与状态机.md`
> 本篇是首版接口边界的落地契约，供 B（登录注册/科室号源）、C（挂号接口）、D（管理端）在 ⑤⑥⑧ 阶段直接对齐字段与错误码；实现代码位于 `common` 包：`ApiResponse`、`PageResult`、`ErrorCode`、`BusinessException`。

## 1. 通用约定

- **认证**：除注册/登录外，所有接口需在请求头携带 `Authorization: Bearer <token>`；未带/失效返回 401，角色不匹配返回 403。
- **统一响应体**：所有接口返回 `ApiResponse<T>`：

  ```json
  { "code": 200, "message": "操作成功", "data": { } }
  ```

- **列表接口分页**：`data` 为 `PageResult<T>`：

  ```json
  { "code": 200, "message": "操作成功", "data": { "records": [ ], "total": 42, "page": 1, "size": 10 } }
  ```

  查询参数统一使用 `page`（从 1 开始）、`size`。
- **时间与金额**：时间使用 ISO 8601（`Asia/Shanghai`），金额字段为整数分（如 `fee_fen`），前端负责格式化展示。
- **幂等**：所有会产生资源或改变库存/状态的写接口（下单、支付、取消）必须支持幂等键或状态条件更新，具体见 `docs/06-挂号流程与状态机.md`。
- **删除语义**：后台删除接口均为逻辑删除（`enabled=0` 或 `deleted=1`），不做物理删除；被引用中的资源禁止停用/删除，返回 `409005`。

## 2. 错误码目录

框架级错误沿用 HTTP 状态码作为 `code`（由 `GlobalExceptionHandler` 统一处理，无需业务代码关注）：

| code | HTTP | 说明 | 触发来源 |
| --- | --- | --- | --- |
| 400 | 400 | 参数校验失败 | `@Valid` 注解 / `ConstraintViolationException` |
| 400 | 400 | 请求体格式不正确 | JSON 解析失败 |
| 401 | 401 | 未登录或 Token 失效 | Spring Security 认证失败 |
| 403 | 403 | 无权限访问 | 角色不匹配路由 |
| 500 | 500 | 系统繁忙，请稍后重试 | 未捕获异常 |

业务级错误使用 `ErrorCode` 枚举（业务代码通过 `throw new BusinessException(ErrorCode.XXX)` 抛出，由 `GlobalExceptionHandler` 统一转换为对应 HTTP 状态与响应体）：

| code | HTTP | 枚举 | 说明 | 典型场景 |
| --- | --- | --- | --- | --- |
| 409001 | 409 | `PHONE_ALREADY_REGISTERED` | 手机号已注册 | APP-01 注册重复（T01） |
| 409002 | 409 | `CONTACT_ID_CARD_DUPLICATED` | 该身份证已绑定其他就诊人 | APP-07 重复绑定（T03） |
| 409003 | 409 | `SLOT_SOLD_OUT` | 该时段已约满或状态已变化 | 预约下单条件更新失败（T06） |
| 409004 | 409 | `ORDER_STATUS_CONFLICT` | 订单状态已变化，操作不可执行 | 重复支付/取消已终态订单（T07/T08） |
| 409005 | 409 | `REFERENCED_BY_OTHER_RECORD` | 存在关联数据引用，请先停用 | 删除被排班/订单引用的科室/医生/号别（T09） |
| 422001 | 422 | `BUSINESS_RULE_VIOLATION` | 业务规则校验未通过 | 排班规则冲突、限额非法等 |

> 新增业务错误码须先在本表登记再编码，避免前后端字段/文案不一致。

## 3. 接口清单

### 3.1 鉴权（B 负责实现）

> 路径以实际实现为准：患者端在 `/api/app/auth/**` 下，管理端在 `/api/admin/auth/**` 下；两组前缀也是 `SecurityConfig` 角色隔离（`ROLE_PATIENT` / `ROLE_ADMIN`）的边界，因此不合并为不带角色前缀的 `/api/auth/**`。

| 方法 | 路径 | 说明 | 请求体 | 成功响应 `data` |
| --- | --- | --- | --- | --- |
| POST | `/api/app/auth/register` | 患者注册（成功后自动登录） | `{phone, password, nickname}` | `LoginResponse` |
| POST | `/api/app/auth/login` | 患者登录 | `{phone, password}` | `LoginResponse` |
| POST | `/api/app/auth/logout` | 患者登出（需 Bearer Token，Token 加入黑名单） | - | 空 |
| POST | `/api/admin/auth/login` | 管理员登录 | `{username, password}` | `LoginResponse` |
| POST | `/api/admin/auth/logout` | 管理员登出（需 Bearer Token，Token 加入黑名单） | - | 空 |

`LoginResponse` 字段：`{accessToken, tokenType, userId, nickname, userType}`；`tokenType` 固定为 `Bearer`，请求头需拼接为 `Authorization: Bearer {accessToken}`。

`register`/`login`/管理员 `login` 免鉴权（`permitAll`）；`logout` 必须携带有效 Token（分别落入 `ROLE_PATIENT`/`ROLE_ADMIN` 鉴权范围)。登出后的 Token 立即失效，重复调用返回 401。

失败：手机号重复 `409001`；账号密码错误 `401`（不区分"账号不存在"与"密码错误"，避免用户枚举）。

### 3.2 患者与就诊人（B 负责实现）

| 方法 | 路径 | 说明 | 请求体/参数 | 成功响应 |
| --- | --- | --- | --- | --- |
| GET | `/api/me` | 当前登录用户信息 | - | `LoginUser` |
| PUT | `/api/me` | 更新昵称/头像 | `{nickname, avatar}` | - |
| GET | `/api/contacts` | 我的就诊人列表 | - | `Contact[]` |
| POST | `/api/contacts` | 新增就诊人 | `{name, idCardNo, phone}` | `{contactId}` |
| PUT | `/api/contacts/{id}` | 编辑就诊人 | `{name, idCardNo, phone}` | - |
| DELETE | `/api/contacts/{id}` | 删除就诊人 | - | - |

失败：身份证重复绑定 `409002`；就诊人存在有效订单时删除返回 `409005`。

### 3.3 基础资料与号源查询（B 已实现，均需 Bearer Token，不区分 PATIENT/ADMIN）

| 方法 | 路径 | 说明 | 参数 | 成功响应 `data` |
| --- | --- | --- | --- | --- |
| GET | `/api/departments/tree` | 科室树，仅 `enabled=1`，`parentId=0` 为根节点 | - | `DepartmentTreeNode[]`：`{id, code, name, description, sortNo, children[]}` |
| GET | `/api/slots` | 号源查询，仅 `status=OPEN` 且 `remainingQuota>0` | `departmentId`（必填）、`date`（必填，`yyyy-MM-dd`，按天查询，前端遍历未来 7 日分别调用）、`levelId`（可选） | `SlotSummary[]`：`{slotId, doctorId, doctorName, doctorAvatarUrl, departmentId, levelId, levelName, feeFen, visitDate, startTime, endTime, remainingQuota}` |
| GET | `/api/doctors/{id}` | 医生详情，含所属科室名称与可提供的挂号级别 | - | `DoctorDetailResponse`：`{id, name, departmentId, departmentName, title, avatarUrl, introduction, levels: [{levelId, code, name, feeFen}]}` |

医生不存在或已下线返回 `404`。

### 3.4 预约订单（C 负责实现，契约见 `docs/06-挂号流程与状态机.md`）

| 方法 | 路径 | 说明 | 请求体 | 成功响应 | 主要错误码 |
| --- | --- | --- | --- | --- | --- |
| POST | `/api/orders` | 创建预约订单 | `{slotId, contactId, idempotencyKey}` | `OrderDetail`（状态 `PENDING_PAYMENT`） | `409003` |
| POST | `/api/orders/{id}/pay` | 模拟支付 | - | `OrderDetail`（状态 `PAID`） | `409004` |
| POST | `/api/orders/{id}/cancel` | 用户取消订单 | `{reason}` | `OrderDetail`（状态 `CANCELLED`） | `409004` |
| GET | `/api/orders` | 我的挂号记录（分页） | `status, page, size` | `PageResult<OrderSummary>` | - |
| GET | `/api/orders/{id}` | 订单详情 | - | `OrderDetail` | `404` |

请求示例（创建订单，命中号源已抢完）：

```json
// POST /api/orders
// Request
{ "slotId": 100234, "contactId": 8801, "idempotencyKey": "b1f0c6c2-..." }

// Response (409)
{ "code": 409003, "message": "该时段已约满或状态已变化", "data": null }
```

### 3.5 后台管理（D 负责实现，均为分页 CRUD + 逻辑删除）

| 方法 | 路径前缀 | 说明 |
| --- | --- | --- |
| `/api/admin/users` | 用户管理 | 列表(分页/筛选)、新增、编辑、停用、逻辑删除 |
| `/api/admin/departments` | 科室管理 | 同上，含父级/类型筛选 |
| `/api/admin/doctors` | 医生管理 | 同上，含科室/号别关联维护 |
| `/api/admin/schedule-rules` | 排班规则管理 | 同上，含规则串预览 |
| `/api/admin/levels` | 挂号级别管理 | 同上，编码唯一 |
| `/api/admin/orders` | 挂号记录管理 | 分页查询 + 管理员取消 |

列表接口统一以 `GET .../list?page=&size=&<筛选字段>` 返回 `PageResult<T>`；新增/编辑用 `POST` / `PUT`；停用与逻辑删除分别为 `PUT .../{id}/status`、`DELETE .../{id}`。删除前置校验引用关系失败时返回 `409005`。

### 3.6 AI 管家（P1，本期契约冻结但不阻塞主线）

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET/PUT | `/api/me/ai-settings` | AI 配置（API Key 仅返回掩码） |
| POST | `/api/ai/chat` | 发送消息（未登录 401） |
| GET | `/api/ai/conversations` | 会话历史 |

## 4. 变更流程

字段、枚举或错误码的任何变更，先在本文件提交 PR/评审，再同步到各端代码；禁止后端先改字段、前端"猜"字段名。冲突以本文件登记时间为准，最新登记覆盖旧约定。
