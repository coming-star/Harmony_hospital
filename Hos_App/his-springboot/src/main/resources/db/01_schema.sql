-- 东软云医院预约挂号系统：MySQL 8.0+ 初始化脚本
--
-- 阅读本文件前先了解几个全局约定：
-- 1. 主键用“雪花算法”生成的 BIGINT，而不是数据库自增(AUTO_INCREMENT)。
--    雪花算法：由应用程序自己拼出一个不会重复的 64 位整数(时间戳+机器号+序号)，
--    好处是以后要把数据库拆成多个库/多个服务时，各自生成的 ID 不会互相冲突；
--    自增 ID 做不到这一点(两个库都可能生成"1、2、3..."，拆库后就重复了)。
-- 2. 金额都以“分”为单位存成整数(比如 500 表示 5.00 元)，前端负责换算成"元"展示，
--    这是为了避免小数(DECIMAL/FLOAT)在计算时出现精度误差。
-- 3. 逻辑删除：凡是带 deleted 字段的表，删除时只把 deleted 改成 1，不做物理删除(不执行真正的 DELETE)。
--    查询时要求默认加上 WHERE deleted=0，这样"删除"的数据其实还留着，可以追溯、也不会误删历史订单关联的资料。
-- 4. 所有时间使用 Asia/Shanghai 时区。

CREATE DATABASE IF NOT EXISTS neusoft_cloud_hospital
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE neusoft_cloud_hospital;

-- ============================================================
-- 一、账号相关：登录用户 + 就诊人
-- ============================================================

-- 系统里所有能登录的账号，患者和管理员共用一张表，用 user_type 区分身份。
CREATE TABLE sys_user (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键，应用层生成',
  username VARCHAR(32) DEFAULT NULL COMMENT '管理员登录账号；患者不使用，此字段为空',
  phone VARCHAR(20) NOT NULL COMMENT '患者登录用的手机号',
  password_hash VARCHAR(100) NOT NULL COMMENT '密码密文，用 BCrypt 加密后存储，不存明文密码',
  nickname VARCHAR(50) NOT NULL DEFAULT '用户',
  avatar_url VARCHAR(500) DEFAULT NULL,
  user_type VARCHAR(16) NOT NULL DEFAULT 'PATIENT' COMMENT '账号类型：ADMIN管理员 / PATIENT患者',
  status TINYINT NOT NULL DEFAULT 1 COMMENT '账号状态：1启用 0停用（停用后不能登录，但数据仍保留）',
  last_login_at DATETIME DEFAULT NULL,
  deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除标记，见文件顶部说明',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_username (username),
  UNIQUE KEY uk_user_phone (phone),
  KEY idx_user_status_created (status, created_at)
) ENGINE=InnoDB COMMENT='系统用户（患者及管理员）';

-- “就诊人”不等于登录账号：一个手机号登录账号下，可以挂多个就诊人（比如帮家人挂号）。
-- 下单时选的是就诊人，不是登录账号本身。
CREATE TABLE patient_contact (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  user_id BIGINT UNSIGNED NOT NULL COMMENT '这个就诊人挂在哪个登录账号下面',
  name VARCHAR(50) NOT NULL,
  id_card_cipher VARBINARY(512) DEFAULT NULL COMMENT '身份证号密文，用 AES-GCM 加密，绝不存明文；本期演示暂不收集身份证，允许为空',
  id_card_hash CHAR(64) DEFAULT NULL COMMENT '身份证号做 SHA-256 哈希后的值，专门用来判断"是不是已经绑过这个身份证"，因为密文每次加密结果不同没法直接比对；本期允许为空',
  phone VARCHAR(20) NOT NULL,
  relation VARCHAR(20) NOT NULL DEFAULT 'SELF' COMMENT '和账号本人的关系：SELF本人/PARENT父母/CHILD子女/SPOUSE配偶/OTHER其他',
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_contact_user_idcard (user_id, id_card_hash),
  KEY idx_contact_user_deleted (user_id, deleted)
) ENGINE=InnoDB COMMENT='就诊人；一名账户可绑定多个';

-- ============================================================
-- 二、基础资料：科室 / 挂号级别 / 医生
-- ============================================================

-- 科室支持两级（比如"内科"下面挂"心血管内科"），parent_id=0 表示这是一级科室。
CREATE TABLE department (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  code VARCHAR(32) NOT NULL COMMENT '科室编码，全局唯一，管理端用来快速定位',
  name VARCHAR(100) NOT NULL,
  parent_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '上级科室ID，0表示这是一级科室（没有上级）',
  department_type VARCHAR(20) NOT NULL DEFAULT 'CLINICAL' COMMENT '科室类型：CLINICAL临床科室/MEDICAL_TECHNOLOGY医技科室/OTHER其他',
  description VARCHAR(500) DEFAULT NULL,
  sort_no INT NOT NULL DEFAULT 0 COMMENT '排序号，数字越小越靠前',
  enabled TINYINT NOT NULL DEFAULT 1 COMMENT '是否启用：1启用 0停用（停用不等于删除，患者端不再展示）',
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_department_code (code),
  KEY idx_department_parent_enabled_sort (parent_id, enabled, sort_no)
) ENGINE=InnoDB COMMENT='科室树；本期主要使用两级';

-- “挂号级别”就是常说的号别，比如普通号、专家号，决定挂号费和限号数量。
CREATE TABLE registration_level (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  code VARCHAR(32) NOT NULL COMMENT '号别编码，全局唯一',
  name VARCHAR(50) NOT NULL COMMENT '号别名称，如"普通号""专家号"',
  fee_fen INT UNSIGNED NOT NULL COMMENT '挂号费，单位是"分"（500=5元），避免小数精度问题',
  default_quota INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '默认限号数，仅供新建排班规则时参考填值，不直接约束库存',
  sort_no INT NOT NULL DEFAULT 0,
  enabled TINYINT NOT NULL DEFAULT 1,
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_level_code (code),
  KEY idx_level_enabled_sort (enabled, sort_no)
) ENGINE=InnoDB COMMENT='挂号级别，如普通号、专家号';

-- 医生档案本身；这个医生具体能挂哪些科室的号、提供哪些号别，由下面两张关联表决定。
CREATE TABLE doctor (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  name VARCHAR(50) NOT NULL,
  department_id BIGINT UNSIGNED NOT NULL COMMENT '所属科室',
  title VARCHAR(50) DEFAULT NULL COMMENT '职称，如"主任医师"',
  introduction TEXT DEFAULT NULL COMMENT '医生简介，患者端预约页会展示',
  enabled TINYINT NOT NULL DEFAULT 1,
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_doctor_department_enabled (department_id, enabled)
) ENGINE=InnoDB COMMENT='医生档案';

-- 一名医生可以同时提供多种号别（比如既出普通号也出专家号），所以单独用一张关联表，
-- 而不是在 doctor 表里加一个 level_id 字段（那样一个医生就只能挂一种号别了）。
CREATE TABLE doctor_registration_level (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  doctor_id BIGINT UNSIGNED NOT NULL,
  level_id BIGINT UNSIGNED NOT NULL,
  enabled TINYINT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_doctor_level (doctor_id, level_id),
  KEY idx_drl_level_enabled (level_id, enabled)
) ENGINE=InnoDB COMMENT='医生可提供的挂号级别';

-- ============================================================
-- 三、排班与号源：先有"规则"，再由规则生成"实际可约的时段"
-- ============================================================

-- 排班规则是"周期性的模板"，比如"周一三五上午"，本身是纯规则，不绑定特定医生。
-- 多个医生可以复用同一条规则（通过 doctor_schedule_rule 中间表关联）。
-- 系统会用"医生+规则"的组合，按天展开生成 schedule_slot（实际号源），患者预约的是号源，不是规则。
CREATE TABLE schedule_rule (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  level_id BIGINT UNSIGNED NOT NULL COMMENT '该规则对应的号别，如普通号/专家号',
  rule_name VARCHAR(100) NOT NULL COMMENT '排班说明文字，如"周一三五上午"',
  weekday_mask TINYINT UNSIGNED NOT NULL COMMENT '用二进制位表示星期几生效：从低位到高位第0-6位依次对应周一到周日，命中的位=1。例如周一三五生效，二进制是0010101，换算成十进制就是21',
  period VARCHAR(16) NOT NULL COMMENT '时段：MORNING上午/AFTERNOON下午/EVENING晚上/FULL全天',
  slots_json JSON NOT NULL COMMENT '具体时段与限额，格式如 [{start:"08:00",end:"08:30",quota:10}]，一条规则里可以有多个时段',
  effective_start DATE NOT NULL COMMENT '规则生效开始日期',
  effective_end DATE DEFAULT NULL COMMENT '规则生效结束日期，NULL表示一直有效、没有结束时间',
  enabled TINYINT NOT NULL DEFAULT 1,
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_rule_level_enabled (level_id, enabled),
  KEY idx_rule_effective_range (effective_start, effective_end)
) ENGINE=InnoDB COMMENT='周期性排班规则模板；多个医生可复用';

-- 医生 ↔ 排班规则 多对多关联表。
-- 一条规则可以被多个医生复用；一个医生可以同时采用多条规则（例如既出周一周三上午也出周六全天）。
CREATE TABLE doctor_schedule_rule (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  doctor_id BIGINT UNSIGNED NOT NULL,
  schedule_rule_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_doctor_rule (doctor_id, schedule_rule_id),
  KEY idx_dsr_rule (schedule_rule_id)
) ENGINE=InnoDB COMMENT='医生-排班规则关联；多对多模板复用';

-- 这是患者真正能预约的"号源"，每一行代表"某医生在某天某个具体时间段，还剩几个名额"。
-- 挂号下单时，只对这张表做"扣库存"操作（remaining_quota 减 1），不会去改 schedule_rule。
CREATE TABLE schedule_slot (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  schedule_rule_id BIGINT UNSIGNED DEFAULT NULL COMMENT '这个号源是由哪条排班规则自动生成的；如果是管理员手动临时加的号，这里是NULL',
  doctor_id BIGINT UNSIGNED NOT NULL,
  department_id BIGINT UNSIGNED NOT NULL,
  level_id BIGINT UNSIGNED NOT NULL,
  visit_date DATE NOT NULL COMMENT '就诊日期',
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  total_quota INT UNSIGNED NOT NULL COMMENT '这个时段总共放出多少个号',
  remaining_quota INT UNSIGNED NOT NULL COMMENT '还剩多少个号没被预约；每成功下单一次就减1，取消/超时就加回1',
  status VARCHAR(16) NOT NULL DEFAULT 'OPEN' COMMENT '号源状态：OPEN可约/CLOSED已停诊/CANCELLED已取消',
  version INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '乐观锁版本号：多个人同时抢最后一个号时，靠这个字段保证不会超卖，详见 docs/06',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_slot_doctor_date_time_level (doctor_id, visit_date, start_time, end_time, level_id),
  KEY idx_slot_department_date_level (department_id, visit_date, level_id, status),
  KEY idx_slot_doctor_date (doctor_id, visit_date, status),
  CONSTRAINT chk_slot_quota CHECK (remaining_quota <= total_quota)
) ENGINE=InnoDB COMMENT='可预约实际时段；订单以此表为唯一扣号依据';

-- ============================================================
-- 四、挂号订单与支付
-- ============================================================

-- 患者预约成功后生成的订单。医生/科室/号别/费用等信息在下单那一刻就"拍快照"存进这张表里，
-- 这样以后就算医生改了科室、号别改了价格，历史订单显示的还是当时下单那一刻的真实信息。
CREATE TABLE registration_order (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  order_no VARCHAR(32) NOT NULL COMMENT '订单编号，展示给用户看的那个号',
  user_id BIGINT UNSIGNED NOT NULL COMMENT '下单的登录账号',
  contact_id BIGINT UNSIGNED NOT NULL COMMENT '这次是给哪个就诊人挂的号',
  slot_id BIGINT UNSIGNED NOT NULL COMMENT '预约的具体号源',
  doctor_id BIGINT UNSIGNED NOT NULL COMMENT '冗余存一份医生ID，方便直接按医生筛选订单，不用每次都关联查 schedule_slot',
  department_id BIGINT UNSIGNED NOT NULL,
  level_id BIGINT UNSIGNED NOT NULL,
  doctor_name_snapshot VARCHAR(50) NOT NULL COMMENT '下单时刻的医生姓名快照',
  department_name_snapshot VARCHAR(100) NOT NULL COMMENT '下单时刻的科室名称快照',
  level_name_snapshot VARCHAR(50) NOT NULL COMMENT '下单时刻的号别名称快照',
  visit_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  amount_fen INT UNSIGNED NOT NULL COMMENT '订单金额，单位"分"',
  status VARCHAR(24) NOT NULL DEFAULT 'PENDING_PAYMENT' COMMENT '订单状态：PENDING_PAYMENT待支付/PAID已支付/CANCELLED已取消/COMPLETED已完成，状态机详见 docs/06',
  expired_at DATETIME NOT NULL COMMENT '待支付超时时间，超过这个时间还没支付会被自动取消',
  paid_at DATETIME DEFAULT NULL,
  cancelled_at DATETIME DEFAULT NULL,
  cancel_reason VARCHAR(255) DEFAULT NULL COMMENT '取消来源：USER患者主动取消/ADMIN管理员取消/TIMEOUT超时自动取消',
  idempotency_key VARCHAR(64) DEFAULT NULL COMMENT '客户端生成的幂等键，防止网络重试导致同一次点击生成两笔订单',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_order_no (order_no),
  UNIQUE KEY uk_order_user_idempotency (user_id, idempotency_key),
  KEY idx_order_user_status_created (user_id, status, created_at),
  KEY idx_order_slot_status (slot_id, status),
  KEY idx_order_expire_status (expired_at, status),
  KEY idx_order_contact_date (contact_id, visit_date)
) ENGINE=InnoDB COMMENT='挂号预约订单；名称、费用、时间均保存快照';

-- 支付流水，跟订单是一对一关系。本期没有接入真实支付渠道，用"模拟支付"，
-- 点一下"支付"按钮，这张表就直接把状态改成 SUCCESS，不会真的扣钱。
CREATE TABLE payment_record (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  order_id BIGINT UNSIGNED NOT NULL,
  channel VARCHAR(20) NOT NULL DEFAULT 'MOCK' COMMENT '支付渠道，本期固定为 MOCK（模拟支付），以后可以扩展成微信/支付宝',
  trade_no VARCHAR(64) DEFAULT NULL COMMENT '第三方支付平台的交易号，模拟支付下是自己生成的假号',
  amount_fen INT UNSIGNED NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'INIT' COMMENT '支付状态：INIT待支付/SUCCESS支付成功/FAILED支付失败/CLOSED已关闭',
  paid_at DATETIME DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_payment_order (order_id),
  UNIQUE KEY uk_payment_trade_no (trade_no)
) ENGINE=InnoDB COMMENT='支付流水；模拟支付也写入本表';

-- ============================================================
-- 五、AI 管家：会话与消息
-- ============================================================
-- 说明：AI 接入用的 API Key 统一由项目配置管理（写在后端配置里），
-- 不做"每个患者自己填一个密钥"的个人配置，所以这里不建 ai_user_setting 表。
-- 下面两张表只负责存"聊天记录"，跟密钥配置无关。

-- 一条会话＝患者和AI的一个聊天窗口/一个话题，类似聊天软件里的"会话列表"。
CREATE TABLE ai_conversation (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(100) NOT NULL DEFAULT '新对话' COMMENT '会话标题，患者打开AI管家时看到的列表项名字',
  last_message_at DATETIME DEFAULT NULL COMMENT '最后一条消息的时间，用于会话列表排序',
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_conversation_user_last (user_id, deleted, last_message_at)
) ENGINE=InnoDB COMMENT='AI 对话会话';

-- 会话里的每一条具体消息，一问一答各是一行。
CREATE TABLE ai_message (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  conversation_id BIGINT UNSIGNED NOT NULL COMMENT '属于哪个会话',
  role VARCHAR(16) NOT NULL COMMENT '这句话是谁说的：USER患者发的/ASSISTANT AI回复的/SYSTEM系统提示词/TOOL AI调用查号源等工具时的记录',
  content TEXT NOT NULL,
  extra_json JSON DEFAULT NULL COMMENT '扩展数据：ASSISTANT 消息附带的号源卡片列表(SlotSummary JSON数组)，重开会话时用于还原卡片',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_message_conversation_created (conversation_id, created_at)
) ENGINE=InnoDB COMMENT='AI 对话消息；须做长度限制与敏感日志隔离';

-- ============================================================
-- 六、消息中心：站内信
-- ============================================================

-- 站内信：订单状态通知（预约成功/患者取消/管理员取消/超时取消）与就诊提醒都写进这张表。
-- 数据来源：订单事件由 RocketMQ 消费者（order_event_topic）写入；就诊提醒由定时任务每 10 分钟扫描写入。
-- App 端"我的-消息"页拉取展示；未读数用于"我的"Tab 图标红点。
CREATE TABLE message (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花主键',
  user_id BIGINT UNSIGNED NOT NULL COMMENT '消息归属的登录账号',
  type VARCHAR(32) NOT NULL COMMENT '消息类型：ORDER_PAY_SUCCESS预约成功/ORDER_CANCELLED订单已取消/ORDER_TIMEOUT订单超时取消/VISIT_REMINDER就诊提醒',
  title VARCHAR(100) NOT NULL COMMENT '消息标题，列表页直接展示',
  content VARCHAR(500) NOT NULL COMMENT '消息正文',
  biz_id BIGINT UNSIGNED DEFAULT NULL COMMENT '关联业务ID，一般是订单ID，点击可跳订单详情',
  dedup_key VARCHAR(100) DEFAULT NULL COMMENT '防重键：订单事件为"事件类型:订单ID"，就诊提醒为"订单ID:REMIND_24H/REMIND_3H"；唯一索引保证不重复发送',
  is_read TINYINT NOT NULL DEFAULT 0 COMMENT '是否已读：0未读 1已读',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_message_dedup (dedup_key),
  KEY idx_message_user_read_created (user_id, is_read, created_at)
) ENGINE=InnoDB COMMENT='站内信(消息中心)；订单通知与就诊提醒共用';
