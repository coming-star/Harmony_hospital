-- 东软云医院预约挂号系统：MySQL 8.0+ 初始化脚本
-- 约定：所有时间均使用 Asia/Shanghai 业务时间；金额均以“分”存储。
-- 逻辑删除：deleted=0 有效，deleted=1 已删除。删除基础资料前须由应用层检查引用关系。

CREATE DATABASE IF NOT EXISTS neusoft_cloud_hospital
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE neusoft_cloud_hospital;

CREATE TABLE sys_user (
  id BIGINT UNSIGNED NOT NULL COMMENT '雪花/号段主键',
  username VARCHAR(32) DEFAULT NULL COMMENT '管理员登录账号；患者为空并使用手机号登录',
  phone VARCHAR(20) NOT NULL COMMENT '登录手机号',
  password_hash VARCHAR(100) NOT NULL COMMENT 'BCrypt 密文',
  nickname VARCHAR(50) NOT NULL DEFAULT '用户',
  avatar_url VARCHAR(500) DEFAULT NULL,
  user_type VARCHAR(16) NOT NULL DEFAULT 'PATIENT' COMMENT 'ADMIN/PATIENT',
  status TINYINT NOT NULL DEFAULT 1 COMMENT '1启用 0禁用',
  last_login_at DATETIME DEFAULT NULL,
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_username (username),
  UNIQUE KEY uk_user_phone (phone),
  KEY idx_user_status_created (status, created_at)
) ENGINE=InnoDB COMMENT='系统用户（患者及管理员）';

CREATE TABLE patient_contact (
  id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL COMMENT '所属账户',
  name VARCHAR(50) NOT NULL,
  id_card_cipher VARBINARY(512) NOT NULL COMMENT '身份证 AES-GCM 密文，不可明文保存',
  id_card_hash CHAR(64) NOT NULL COMMENT '身份证规范化后 SHA-256，用于判重',
  phone VARCHAR(20) NOT NULL,
  relation VARCHAR(20) NOT NULL DEFAULT 'SELF' COMMENT 'SELF/PARENT/CHILD/SPOUSE/OTHER',
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_contact_user_idcard (user_id, id_card_hash),
  KEY idx_contact_user_deleted (user_id, deleted)
) ENGINE=InnoDB COMMENT='就诊人；一名账户可绑定多个';

CREATE TABLE department (
  id BIGINT UNSIGNED NOT NULL,
  code VARCHAR(32) NOT NULL,
  name VARCHAR(100) NOT NULL,
  parent_id BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0为一级科室',
  department_type VARCHAR(20) NOT NULL DEFAULT 'CLINICAL' COMMENT 'CLINICAL/MEDICAL_TECHNOLOGY/OTHER',
  description VARCHAR(500) DEFAULT NULL,
  sort_no INT NOT NULL DEFAULT 0,
  enabled TINYINT NOT NULL DEFAULT 1,
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_department_code (code),
  KEY idx_department_parent_enabled_sort (parent_id, enabled, sort_no)
) ENGINE=InnoDB COMMENT='科室树；本期主要使用两级';

CREATE TABLE registration_level (
  id BIGINT UNSIGNED NOT NULL,
  code VARCHAR(32) NOT NULL,
  name VARCHAR(50) NOT NULL,
  fee_fen INT UNSIGNED NOT NULL COMMENT '挂号费，单位：分',
  default_quota INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '默认号源限额，仅供创建规则时参考',
  sort_no INT NOT NULL DEFAULT 0,
  enabled TINYINT NOT NULL DEFAULT 1,
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_level_code (code),
  KEY idx_level_enabled_sort (enabled, sort_no)
) ENGINE=InnoDB COMMENT='挂号级别，如普通号、专家号';

CREATE TABLE doctor (
  id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(50) NOT NULL,
  department_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(50) DEFAULT NULL COMMENT '如主任医师',
  avatar_url VARCHAR(500) DEFAULT NULL,
  introduction TEXT DEFAULT NULL,
  enabled TINYINT NOT NULL DEFAULT 1,
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_doctor_department_enabled (department_id, enabled)
) ENGINE=InnoDB COMMENT='医生档案';

CREATE TABLE doctor_registration_level (
  id BIGINT UNSIGNED NOT NULL,
  doctor_id BIGINT UNSIGNED NOT NULL,
  level_id BIGINT UNSIGNED NOT NULL,
  enabled TINYINT NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_doctor_level (doctor_id, level_id),
  KEY idx_drl_level_enabled (level_id, enabled)
) ENGINE=InnoDB COMMENT='医生可提供的挂号级别';

CREATE TABLE schedule_rule (
  id BIGINT UNSIGNED NOT NULL,
  doctor_id BIGINT UNSIGNED NOT NULL,
  level_id BIGINT UNSIGNED NOT NULL,
  rule_name VARCHAR(100) NOT NULL COMMENT '如周一三五上午专家号',
  weekday_mask TINYINT UNSIGNED NOT NULL COMMENT 'bit0-6 对应周一至周日；周一三五=21',
  period VARCHAR(16) NOT NULL COMMENT 'MORNING/AFTERNOON/EVENING',
  slots_json JSON NOT NULL COMMENT '时段数组：[{start:"08:00",end:"08:30",quota:10}]',
  effective_start DATE NOT NULL,
  effective_end DATE DEFAULT NULL COMMENT 'NULL表示长期有效',
  enabled TINYINT NOT NULL DEFAULT 1,
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_rule_doctor_level_enabled (doctor_id, level_id, enabled),
  KEY idx_rule_effective_range (effective_start, effective_end)
) ENGINE=InnoDB COMMENT='周期性排班规则；由任务展开成实际号源';

CREATE TABLE schedule_slot (
  id BIGINT UNSIGNED NOT NULL,
  schedule_rule_id BIGINT UNSIGNED DEFAULT NULL COMMENT 'NULL表示人工加号',
  doctor_id BIGINT UNSIGNED NOT NULL,
  department_id BIGINT UNSIGNED NOT NULL,
  level_id BIGINT UNSIGNED NOT NULL,
  visit_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  total_quota INT UNSIGNED NOT NULL,
  remaining_quota INT UNSIGNED NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'OPEN' COMMENT 'OPEN/CLOSED/CANCELLED',
  version INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '乐观锁版本',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_slot_doctor_date_time_level (doctor_id, visit_date, start_time, end_time, level_id),
  KEY idx_slot_department_date_level (department_id, visit_date, level_id, status),
  KEY idx_slot_doctor_date (doctor_id, visit_date, status),
  CONSTRAINT chk_slot_quota CHECK (remaining_quota <= total_quota)
) ENGINE=InnoDB COMMENT='可预约实际时段；订单以此表为唯一扣号依据';

CREATE TABLE registration_order (
  id BIGINT UNSIGNED NOT NULL,
  order_no VARCHAR(32) NOT NULL COMMENT '业务订单号',
  user_id BIGINT UNSIGNED NOT NULL COMMENT '下单账户',
  contact_id BIGINT UNSIGNED NOT NULL COMMENT '就诊人',
  slot_id BIGINT UNSIGNED NOT NULL,
  doctor_id BIGINT UNSIGNED NOT NULL COMMENT '冗余快照关联，便于查询',
  department_id BIGINT UNSIGNED NOT NULL,
  level_id BIGINT UNSIGNED NOT NULL,
  doctor_name_snapshot VARCHAR(50) NOT NULL,
  department_name_snapshot VARCHAR(100) NOT NULL,
  level_name_snapshot VARCHAR(50) NOT NULL,
  visit_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  amount_fen INT UNSIGNED NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'PENDING_PAYMENT' COMMENT 'PENDING_PAYMENT/PAID/CANCELLED/COMPLETED',
  expired_at DATETIME NOT NULL,
  paid_at DATETIME DEFAULT NULL,
  cancelled_at DATETIME DEFAULT NULL,
  cancel_reason VARCHAR(255) DEFAULT NULL,
  idempotency_key VARCHAR(64) DEFAULT NULL COMMENT '客户端提交幂等键',
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

CREATE TABLE payment_record (
  id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NOT NULL,
  channel VARCHAR(20) NOT NULL DEFAULT 'MOCK' COMMENT '本期为 MOCK，后续可扩展微信/支付宝',
  trade_no VARCHAR(64) DEFAULT NULL,
  amount_fen INT UNSIGNED NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'INIT' COMMENT 'INIT/SUCCESS/FAILED/CLOSED',
  paid_at DATETIME DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_payment_order (order_id),
  UNIQUE KEY uk_payment_trade_no (trade_no)
) ENGINE=InnoDB COMMENT='支付流水；模拟支付也写入本表';

CREATE TABLE sys_banner (
  id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(100) NOT NULL,
  image_url VARCHAR(500) NOT NULL,
  link_url VARCHAR(500) DEFAULT NULL,
  sort_no INT NOT NULL DEFAULT 0,
  enabled TINYINT NOT NULL DEFAULT 1,
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_banner_enabled_sort (enabled, sort_no)
) ENGINE=InnoDB COMMENT='移动端首页轮播图';

CREATE TABLE ai_user_setting (
  id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  base_url VARCHAR(500) DEFAULT NULL,
  api_key_cipher VARBINARY(1024) DEFAULT NULL COMMENT '加密保存；查询接口仅返回掩码',
  model_name VARCHAR(100) DEFAULT NULL,
  history_rounds TINYINT UNSIGNED NOT NULL DEFAULT 6,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_ai_setting_user (user_id)
) ENGINE=InnoDB COMMENT='患者个人 AI 接入配置';

CREATE TABLE ai_conversation (
  id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(100) NOT NULL DEFAULT '新对话',
  last_message_at DATETIME DEFAULT NULL,
  deleted TINYINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_conversation_user_last (user_id, deleted, last_message_at)
) ENGINE=InnoDB COMMENT='AI 对话会话';

CREATE TABLE ai_message (
  id BIGINT UNSIGNED NOT NULL,
  conversation_id BIGINT UNSIGNED NOT NULL,
  role VARCHAR(16) NOT NULL COMMENT 'USER/ASSISTANT/SYSTEM/TOOL',
  content TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_message_conversation_created (conversation_id, created_at)
) ENGINE=InnoDB COMMENT='AI 对话消息；须做长度限制与敏感日志隔离';

CREATE TABLE operation_log (
  id BIGINT UNSIGNED NOT NULL,
  operator_id BIGINT UNSIGNED DEFAULT NULL,
  module VARCHAR(50) NOT NULL,
  action VARCHAR(50) NOT NULL,
  request_id VARCHAR(64) DEFAULT NULL,
  detail JSON DEFAULT NULL COMMENT '不得写入密码、完整身份证、API Key',
  ip VARCHAR(45) DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_log_operator_created (operator_id, created_at),
  KEY idx_log_module_action_created (module, action, created_at)
) ENGINE=InnoDB COMMENT='管理端操作审计日志';
