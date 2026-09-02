-- 东软云医院预约挂号系统：演示基础数据（MySQL 8.0+）
-- 前置条件：已执行 01_schema.sql。
-- 本脚本仅使用虚构的机构/人员/号码，不包含真实个人信息。
-- 可安全重复执行：基础资料按业务唯一键忽略重复，未来 7 天号源按时段唯一键忽略重复。
--
-- 预置管理员：admin / admin123；患者账号密码均为 password（仅限本地开发环境），上线前必须删除/重置。
-- BCrypt hash: password / admin123

USE neusoft_cloud_hospital;

SET @bcrypt_password = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy';
SET @bcrypt_admin123 = '$2b$10$VDH7yRJcWzaT3chXGQo2DOCpksKEmbzKYLQ7M1uM0FITRYAgoO3Jm';

INSERT IGNORE INTO sys_user
  (id, username, phone, password_hash, nickname, user_type, status, created_at)
VALUES
  (10001, 'admin', '13800000001', @bcrypt_admin123, '系统管理员', 'ADMIN', 1, NOW()),
  (10002, NULL, '13800000002', @bcrypt_password, '张晓晨', 'PATIENT', 1, NOW()),
  (10003, NULL, '13800000003', @bcrypt_password, '李思远', 'PATIENT', 1, NOW()),
  (10004, NULL, '13800000004', @bcrypt_password, '王雨桐', 'PATIENT', 1, NOW()),
  (10005, NULL, '13800000005', @bcrypt_password, '停用演示用户', 'PATIENT', 0, NOW());

-- 就诊人：一个账号可以绑定多个就诊人（帮家人挂号）。本期演示暂不收集身份证，id_card_* 留空。
INSERT IGNORE INTO patient_contact
  (id, user_id, name, phone, relation, created_at)
VALUES
  (4801, 10002, '张晓晨', '13800000002', 'SELF', NOW()),
  (4802, 10002, '张建国', '13900000002', 'PARENT', NOW()),
  (4803, 10003, '李思远', '13800000003', 'SELF', NOW()),
  (4804, 10004, '王雨桐', '13800000004', 'SELF', NOW());

INSERT IGNORE INTO department
  (id, code, name, parent_id, department_type, description, sort_no, enabled)
VALUES
  (2001, 'MED', '内科', 0, 'CLINICAL', '心血管、呼吸、消化、神经、内分泌等内脏系统疾病。', 10, 1),
  (2002, 'SUR', '外科', 0, 'CLINICAL', '普外、骨科、泌尿等外科疾病诊疗。', 20, 1),
  (2003, 'WOMCHILD', '妇儿科', 0, 'CLINICAL', '妇产与儿童健康相关诊疗服务。', 30, 1),
  (2004, 'TCM', '中医科', 0, 'CLINICAL', '中医内科、针灸推拿等特色诊疗。', 40, 1),
  (2101, 'MED-CV', '心血管内科', 2001, 'CLINICAL', '高血压、冠心病、心律失常、心力衰竭等。', 11, 1),
  (2102, 'MED-NEU', '神经内科', 2001, 'CLINICAL', '脑血管病、头痛头晕、癫痫及神经系统疾病。', 12, 1),
  (2103, 'MED-GI', '消化内科', 2001, 'CLINICAL', '胃肠、肝胆胰疾病及消化道不适。', 13, 1),
  (2104, 'MED-RESP', '呼吸内科', 2001, 'CLINICAL', '咳嗽、哮喘、慢阻肺、肺部感染等。', 14, 1),
  (2201, 'SUR-GEN', '普通外科', 2002, 'CLINICAL', '甲状腺、乳腺、胃肠、肝胆胰脾等。', 21, 1),
  (2202, 'SUR-ORTHO', '骨科', 2002, 'CLINICAL', '骨关节、脊柱、创伤与运动损伤。', 22, 1),
  (2301, 'WOM-OBGYN', '妇科', 2003, 'CLINICAL', '妇科炎症、内分泌及妇科常见病。', 31, 1),
  (2302, 'CHILD-PED', '儿科', 2003, 'CLINICAL', '儿童常见病、生长发育及儿童保健。', 32, 1),
  (2401, 'TCM-INT', '中医内科', 2004, 'CLINICAL', '中医辨证调理与常见内科病诊疗。', 41, 1);

INSERT IGNORE INTO registration_level
  (id, code, name, fee_fen, default_quota, sort_no, enabled)
VALUES
  (3001, 'GENERAL', '普通号', 1000, 20, 10, 1),
  (3002, 'EXPERT', '专家号', 3000, 10, 20, 1),
  (3003, 'CHIEF', '主任医师号', 5000, 8, 30, 1);

INSERT IGNORE INTO doctor
  (id, name, department_id, title, introduction, enabled)
VALUES
  (4001, '陈明远', 2101, '主任医师', '从事心血管内科临床与教学工作二十余年，擅长高血压、冠心病及心律失常管理。', 1),
  (4002, '周宁', 2101, '副主任医师', '擅长心血管常见病诊治及慢病随访。', 1),
  (4003, '赵安然', 2102, '主任医师', '擅长脑血管疾病、头痛眩晕与睡眠障碍诊治。', 1),
  (4004, '孙悦', 2103, '主治医师', '擅长胃肠道疾病、脂肪肝及消化不良诊疗。', 1),
  (4005, '何志诚', 2104, '副主任医师', '擅长慢性咳嗽、哮喘及呼吸道感染诊疗。', 1),
  (4006, '吴清雅', 2201, '主任医师', '擅长甲状腺、乳腺及胃肠外科常见疾病。', 1),
  (4007, '林峰', 2202, '副主任医师', '擅长关节运动损伤、骨折康复及脊柱退变性疾病。', 1),
  (4008, '许星河', 2302, '主治医师', '擅长儿童呼吸道、消化道常见病和儿童保健。', 1),
  (4009, '唐静', 2301, '副主任医师', '擅长妇科炎症、月经异常及妇科常见疾病诊疗。', 1),
  (4010, '高文博', 2401, '主治医师', '擅长中医内科常见病辨证调理和亚健康管理。', 1);

INSERT IGNORE INTO doctor_registration_level (id, doctor_id, level_id, enabled)
VALUES
  (4101, 4001, 3003, 1), (4102, 4002, 3002, 1), (4103, 4003, 3003, 1),
  (4104, 4004, 3001, 1), (4105, 4005, 3002, 1), (4106, 4006, 3003, 1),
  (4107, 4007, 3002, 1), (4108, 4008, 3001, 1), (4109, 4009, 3002, 1),
  (4110, 4010, 3001, 1);

-- weekday_mask：31 表示周一至周五；127 表示每天；21 表示周一三五；42 表示周二四六；63 表示周一至周六；10 表示周二四；84 表示周三/五/日；96 表示周六/日；7 表示周一/二/三。
-- slots_json：管理后台编辑的原始规则。注意：现在 schedule_rule 是"模板"，不包含医生信息，多个医生可以复用同一条规则。
INSERT IGNORE INTO schedule_rule
  (id, level_id, rule_name, weekday_mask, period, slots_json, effective_start, effective_end, enabled)
VALUES
  (5001, 3003, '周一、周三、周五上午', 21, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','08:00','end','08:30','quota',4), JSON_OBJECT('start','08:30','end','09:00','quota',4)), CURDATE(), NULL, 1),
  (5002, 3002, '周二、周四、周六上午', 42, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','09:00','end','09:30','quota',6), JSON_OBJECT('start','09:30','end','10:00','quota',6)), CURDATE(), NULL, 1),
  (5003, 3003, '周二、周四、周六下午', 42, 'AFTERNOON', JSON_ARRAY(JSON_OBJECT('start','14:00','end','14:30','quota',4), JSON_OBJECT('start','14:30','end','15:00','quota',4)), CURDATE(), NULL, 1),
  (5004, 3001, '周一、周三、周五下午', 21, 'AFTERNOON', JSON_ARRAY(JSON_OBJECT('start','14:00','end','14:30','quota',10), JSON_OBJECT('start','14:30','end','15:00','quota',10)), CURDATE(), NULL, 1),
  (5005, 3002, '周一至周六上午', 63, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','08:30','end','09:00','quota',6), JSON_OBJECT('start','09:00','end','09:30','quota',6)), CURDATE(), NULL, 1),
  (5006, 3003, '周二、周四上午', 10, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','08:00','end','08:30','quota',4), JSON_OBJECT('start','08:30','end','09:00','quota',4)), CURDATE(), NULL, 1),
  (5007, 3002, '工作日下午', 31, 'AFTERNOON', JSON_ARRAY(JSON_OBJECT('start','15:00','end','15:30','quota',6), JSON_OBJECT('start','15:30','end','16:00','quota',6)), CURDATE(), NULL, 1),
  (5008, 3001, '周三、周五、周日上午', 84, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','09:00','end','09:30','quota',10), JSON_OBJECT('start','09:30','end','10:00','quota',10)), CURDATE(), NULL, 1),
  (5009, 3002, '周一、周二、周三下午', 7, 'AFTERNOON', JSON_ARRAY(JSON_OBJECT('start','10:00','end','10:30','quota',6), JSON_OBJECT('start','10:30','end','11:00','quota',6)), CURDATE(), NULL, 1),
  (5010, 3001, '周一至周六下午', 63, 'AFTERNOON', JSON_ARRAY(JSON_OBJECT('start','15:00','end','15:30','quota',8), JSON_OBJECT('start','15:30','end','16:00','quota',8)), CURDATE(), NULL, 1);

-- 医生 ↔ 排班规则 多对多关联（一个医生至少一条排班规则）。
-- id 使用 5501 起始（与 schedule_rule 的 5001~5010 错开）。
INSERT IGNORE INTO doctor_schedule_rule
  (id, doctor_id, schedule_rule_id, created_at)
VALUES
  (5501, 4001, 5001, NOW()),
  (5502, 4002, 5002, NOW()),
  (5503, 4003, 5003, NOW()),
  (5504, 4004, 5004, NOW()),
  (5505, 4005, 5005, NOW()),
  (5506, 4006, 5006, NOW()),
  (5507, 4007, 5007, NOW()),
  (5508, 4008, 5008, NOW()),
  (5509, 4009, 5009, NOW()),
  (5510, 4010, 5010, NOW());

-- 在导入当日开始生成 7 个自然日号源。UNION 表中的每行即一个具体可预约时段模板。
INSERT IGNORE INTO schedule_slot
  (id, schedule_rule_id, doctor_id, department_id, level_id, visit_date, start_time, end_time, total_quota, remaining_quota, status, version)
SELECT
  600000 + (t.doctor_id - 4000) * 1000 + d.offset_day * 10 + t.seq,
  t.rule_id, t.doctor_id, t.department_id, t.level_id,
  DATE_ADD(CURDATE(), INTERVAL d.offset_day DAY), t.start_time, t.end_time,
  t.quota, t.quota, 'OPEN', 0
FROM (
  SELECT 0 AS offset_day UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
  UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
) AS d
CROSS JOIN (
  SELECT 5001 rule_id,4001 doctor_id,2101 department_id,3003 level_id,21 mask,1 seq,'08:00:00' start_time,'08:30:00' end_time,4 quota UNION ALL
  SELECT 5001,4001,2101,3003,21,2,'08:30:00','09:00:00',4 UNION ALL
  SELECT 5002,4002,2101,3002,31,1,'09:00:00','09:30:00',6 UNION ALL
  SELECT 5002,4002,2101,3002,31,2,'09:30:00','10:00:00',6 UNION ALL
  SELECT 5003,4003,2102,3003,42,1,'14:00:00','14:30:00',4 UNION ALL
  SELECT 5003,4003,2102,3003,42,2,'14:30:00','15:00:00',4 UNION ALL
  SELECT 5004,4004,2103,3001,31,1,'14:00:00','14:30:00',10 UNION ALL
  SELECT 5004,4004,2103,3001,31,2,'14:30:00','15:00:00',10 UNION ALL
  SELECT 5005,4005,2104,3002,63,1,'08:30:00','09:00:00',6 UNION ALL
  SELECT 5005,4005,2104,3002,63,2,'09:00:00','09:30:00',6 UNION ALL
  SELECT 5006,4006,2201,3003,10,1,'08:00:00','08:30:00',4 UNION ALL
  SELECT 5006,4006,2201,3003,10,2,'08:30:00','09:00:00',4 UNION ALL
  SELECT 5007,4007,2202,3002,31,1,'15:00:00','15:30:00',6 UNION ALL
  SELECT 5007,4007,2202,3002,31,2,'15:30:00','16:00:00',6 UNION ALL
  SELECT 5008,4008,2302,3001,127,1,'09:00:00','09:30:00',10 UNION ALL
  SELECT 5008,4008,2302,3001,127,2,'09:30:00','10:00:00',10 UNION ALL
  SELECT 5009,4009,2301,3002,31,1,'10:00:00','10:30:00',6 UNION ALL
  SELECT 5009,4009,2301,3002,31,2,'10:30:00','11:00:00',6 UNION ALL
  SELECT 5010,4010,2401,3001,63,1,'15:00:00','15:30:00',8 UNION ALL
  SELECT 5010,4010,2401,3001,63,2,'15:30:00','16:00:00',8
) AS t
WHERE ((t.mask >> WEEKDAY(DATE_ADD(CURDATE(), INTERVAL d.offset_day DAY))) & 1) = 1;

-- 扩充科室：新增眼科/口腔科/皮肤科三个一级科室，并补全内科、外科常见二级科室，
-- 让预约首页科室列表更丰满（这些新增科室暂不配置医生，仅用于科室展示）。
INSERT IGNORE INTO department
  (id, code, name, parent_id, department_type, description, sort_no, enabled)
VALUES
  (2005, 'EYE', '眼科', 0, 'CLINICAL', '近视、白内障、青光眼、眼底病变等眼部疾病。', 50, 1),
  (2006, 'STO', '口腔科', 0, 'CLINICAL', '牙体牙髓、口腔修复、正畸、种植等口腔诊疗。', 60, 1),
  (2007, 'DERM', '皮肤科', 0, 'CLINICAL', '皮炎、湿疹、痤疮、皮肤过敏等皮肤疾病。', 70, 1),
  (2105, 'MED-ENDO', '内分泌科', 2001, 'CLINICAL', '糖尿病、甲状腺、痛风及代谢性疾病。', 15, 1),
  (2106, 'MED-NEPH', '肾内科', 2001, 'CLINICAL', '肾炎、肾功能不全、透析与泌尿系统内科疾病。', 16, 1),
  (2107, 'MED-HEMA', '血液内科', 2001, 'CLINICAL', '贫血、血小板减少、白血病等血液系统疾病。', 17, 1),
  (2108, 'MED-INF', '感染内科', 2001, 'CLINICAL', '各类感染性疾病、发热待查与传染病诊疗。', 18, 1),
  (2109, 'MED-GERI', '老年病科', 2001, 'CLINICAL', '老年慢性病、多病共存与老年综合评估管理。', 19, 1),
  (2110, 'MED-RHEU', '风湿免疫科', 2001, 'CLINICAL', '类风湿关节炎、红斑狼疮、痛风等风湿免疫病。', 20, 1),
  (2203, 'SUR-URO', '泌尿外科', 2002, 'CLINICAL', '肾、输尿管、膀胱、前列腺及男科疾病。', 23, 1),
  (2204, 'SUR-THO', '胸外科', 2002, 'CLINICAL', '肺、食管、纵隔等胸部疾病外科治疗。', 24, 1),
  (2205, 'SUR-NEU', '神经外科', 2002, 'CLINICAL', '颅脑外伤、脑肿瘤、脑血管病手术治疗。', 25, 1),
  (2501, 'EYE-GEN', '眼科门诊', 2005, 'CLINICAL', '常见眼病诊疗、视力检查与眼底病筛查。', 51, 1),
  (2601, 'STO-GEN', '口腔科门诊', 2006, 'CLINICAL', '补牙、拔牙、洁牙及口腔常见问题处理。', 61, 1),
  (2701, 'DERM-GEN', '皮肤科门诊', 2007, 'CLINICAL', '常见皮肤病门诊与过敏原检查。', 71, 1);

-- 扩充演示患者账号（密码均为 password），用于制造多用户、多就诊人的挂号记录。
INSERT IGNORE INTO sys_user
  (id, username, phone, password_hash, nickname, user_type, status, created_at)
VALUES
  (10006, NULL, '13800000006', @bcrypt_password, '赵小明', 'PATIENT', 1, NOW()),
  (10007, NULL, '13800000007', @bcrypt_password, '孙丽华', 'PATIENT', 1, NOW());

-- 扩充就诊人：给已有账号补家属就诊人。
INSERT IGNORE INTO patient_contact
  (id, user_id, name, phone, relation, created_at)
VALUES
  (4805, 10006, '赵小明', '13800000006', 'SELF', NOW()),
  (4806, 10007, '孙丽华', '13800000007', 'SELF', NOW()),
  (4807, 10007, '孙小宝', '13800000087', 'CHILD', NOW()),
  (4808, 10003, '李淑芬', '13900000003', 'PARENT', NOW());

-- 预置一批挂号订单（明天及以后的号），覆盖 已支付/待支付/已取消 三种状态，
-- 让管理端"挂号记录"页和患者端"我的挂号"有真实数据可看。
-- 每条订单按医生选最早可约的号源；快照字段直接取医生/科室/号别名称。
INSERT IGNORE INTO registration_order
  (id, order_no, user_id, contact_id, slot_id, doctor_id, department_id, level_id,
   doctor_name_snapshot, department_name_snapshot, level_name_snapshot,
   visit_date, start_time, end_time, amount_fen, status, expired_at, paid_at, cancelled_at, cancel_reason, idempotency_key, created_at)
SELECT 70001, 'SEED70001', 10002, 4802,
       s.id, s.doctor_id, s.department_id, s.level_id,
       doc.name, dep.name, lv.name,
       s.visit_date, s.start_time, s.end_time,
       lv.fee_fen, 'PAID', DATE_ADD(NOW(), INTERVAL 15 MINUTE), NOW(), NULL, NULL, 'seed-70001', NOW()
FROM schedule_slot s
JOIN doctor doc ON doc.id = s.doctor_id
JOIN department dep ON dep.id = s.department_id
JOIN registration_level lv ON lv.id = s.level_id
WHERE s.doctor_id = 4001 AND s.status = 'OPEN' AND s.remaining_quota > 0
  AND s.visit_date >= DATE_ADD(CURDATE(), INTERVAL 1 DAY)
ORDER BY s.visit_date, s.start_time LIMIT 1;

INSERT IGNORE INTO registration_order
  (id, order_no, user_id, contact_id, slot_id, doctor_id, department_id, level_id,
   doctor_name_snapshot, department_name_snapshot, level_name_snapshot,
   visit_date, start_time, end_time, amount_fen, status, expired_at, paid_at, cancelled_at, cancel_reason, idempotency_key, created_at)
SELECT 70002, 'SEED70002', 10003, 4808,
       s.id, s.doctor_id, s.department_id, s.level_id,
       doc.name, dep.name, lv.name,
       s.visit_date, s.start_time, s.end_time,
       lv.fee_fen, 'PAID', DATE_ADD(NOW(), INTERVAL 15 MINUTE), NOW(), NULL, NULL, 'seed-70002', NOW()
FROM schedule_slot s
JOIN doctor doc ON doc.id = s.doctor_id
JOIN department dep ON dep.id = s.department_id
JOIN registration_level lv ON lv.id = s.level_id
WHERE s.doctor_id = 4005 AND s.status = 'OPEN' AND s.remaining_quota > 0
  AND s.visit_date >= DATE_ADD(CURDATE(), INTERVAL 1 DAY)
ORDER BY s.visit_date, s.start_time LIMIT 1;

INSERT IGNORE INTO registration_order
  (id, order_no, user_id, contact_id, slot_id, doctor_id, department_id, level_id,
   doctor_name_snapshot, department_name_snapshot, level_name_snapshot,
   visit_date, start_time, end_time, amount_fen, status, expired_at, paid_at, cancelled_at, cancel_reason, idempotency_key, created_at)
SELECT 70003, 'SEED70003', 10006, 4805,
       s.id, s.doctor_id, s.department_id, s.level_id,
       doc.name, dep.name, lv.name,
       s.visit_date, s.start_time, s.end_time,
       lv.fee_fen, 'PAID', DATE_ADD(NOW(), INTERVAL 15 MINUTE), NOW(), NULL, NULL, 'seed-70003', NOW()
FROM schedule_slot s
JOIN doctor doc ON doc.id = s.doctor_id
JOIN department dep ON dep.id = s.department_id
JOIN registration_level lv ON lv.id = s.level_id
WHERE s.doctor_id = 4004 AND s.status = 'OPEN' AND s.remaining_quota > 0
  AND s.visit_date >= DATE_ADD(CURDATE(), INTERVAL 1 DAY)
ORDER BY s.visit_date, s.start_time LIMIT 1;

INSERT IGNORE INTO registration_order
  (id, order_no, user_id, contact_id, slot_id, doctor_id, department_id, level_id,
   doctor_name_snapshot, department_name_snapshot, level_name_snapshot,
   visit_date, start_time, end_time, amount_fen, status, expired_at, paid_at, cancelled_at, cancel_reason, idempotency_key, created_at)
SELECT 70004, 'SEED70004', 10007, 4807,
       s.id, s.doctor_id, s.department_id, s.level_id,
       doc.name, dep.name, lv.name,
       s.visit_date, s.start_time, s.end_time,
       lv.fee_fen, 'PENDING_PAYMENT', DATE_ADD(NOW(), INTERVAL 15 MINUTE), NULL, NULL, NULL, 'seed-70004', NOW()
FROM schedule_slot s
JOIN doctor doc ON doc.id = s.doctor_id
JOIN department dep ON dep.id = s.department_id
JOIN registration_level lv ON lv.id = s.level_id
WHERE s.doctor_id = 4008 AND s.status = 'OPEN' AND s.remaining_quota > 0
  AND s.visit_date >= DATE_ADD(CURDATE(), INTERVAL 1 DAY)
ORDER BY s.visit_date, s.start_time LIMIT 1;

INSERT IGNORE INTO registration_order
  (id, order_no, user_id, contact_id, slot_id, doctor_id, department_id, level_id,
   doctor_name_snapshot, department_name_snapshot, level_name_snapshot,
   visit_date, start_time, end_time, amount_fen, status, expired_at, paid_at, cancelled_at, cancel_reason, idempotency_key, created_at)
SELECT 70005, 'SEED70005', 10007, 4806,
       s.id, s.doctor_id, s.department_id, s.level_id,
       doc.name, dep.name, lv.name,
       s.visit_date, s.start_time, s.end_time,
       lv.fee_fen, 'PAID', DATE_ADD(NOW(), INTERVAL 15 MINUTE), NOW(), NULL, NULL, 'seed-70005', NOW()
FROM schedule_slot s
JOIN doctor doc ON doc.id = s.doctor_id
JOIN department dep ON dep.id = s.department_id
JOIN registration_level lv ON lv.id = s.level_id
WHERE s.doctor_id = 4009 AND s.status = 'OPEN' AND s.remaining_quota > 0
  AND s.visit_date >= DATE_ADD(CURDATE(), INTERVAL 1 DAY)
ORDER BY s.visit_date, s.start_time LIMIT 1;

INSERT IGNORE INTO registration_order
  (id, order_no, user_id, contact_id, slot_id, doctor_id, department_id, level_id,
   doctor_name_snapshot, department_name_snapshot, level_name_snapshot,
   visit_date, start_time, end_time, amount_fen, status, expired_at, paid_at, cancelled_at, cancel_reason, idempotency_key, created_at)
SELECT 70006, 'SEED70006', 10002, 4801,
       s.id, s.doctor_id, s.department_id, s.level_id,
       doc.name, dep.name, lv.name,
       s.visit_date, s.start_time, s.end_time,
       lv.fee_fen, 'CANCELLED', DATE_ADD(NOW(), INTERVAL 15 MINUTE), NULL, NOW(), 'USER', 'seed-70006', NOW()
FROM schedule_slot s
JOIN doctor doc ON doc.id = s.doctor_id
JOIN department dep ON dep.id = s.department_id
JOIN registration_level lv ON lv.id = s.level_id
WHERE s.doctor_id = 4006 AND s.status = 'OPEN'
  AND s.visit_date >= DATE_ADD(CURDATE(), INTERVAL 1 DAY)
ORDER BY s.visit_date, s.start_time LIMIT 1;

INSERT IGNORE INTO registration_order
  (id, order_no, user_id, contact_id, slot_id, doctor_id, department_id, level_id,
   doctor_name_snapshot, department_name_snapshot, level_name_snapshot,
   visit_date, start_time, end_time, amount_fen, status, expired_at, paid_at, cancelled_at, cancel_reason, idempotency_key, created_at)
SELECT 70007, 'SEED70007', 10004, 4804,
       s.id, s.doctor_id, s.department_id, s.level_id,
       doc.name, dep.name, lv.name,
       s.visit_date, s.start_time, s.end_time,
       lv.fee_fen, 'CANCELLED', DATE_ADD(NOW(), INTERVAL 15 MINUTE), NULL, NOW(), 'USER', 'seed-70007', NOW()
FROM schedule_slot s
JOIN doctor doc ON doc.id = s.doctor_id
JOIN department dep ON dep.id = s.department_id
JOIN registration_level lv ON lv.id = s.level_id
WHERE s.doctor_id = 4003 AND s.status = 'OPEN'
  AND s.visit_date >= DATE_ADD(CURDATE(), INTERVAL 1 DAY)
ORDER BY s.visit_date, s.start_time LIMIT 1;

-- 已支付订单补模拟支付流水。
INSERT IGNORE INTO payment_record (id, order_id, channel, trade_no, amount_fen, status, paid_at, created_at)
SELECT o.id + 100000, o.id, 'MOCK', CONCAT('MOCKSEED', o.id), o.amount_fen, 'SUCCESS', o.paid_at, o.created_at
FROM registration_order o
WHERE o.id IN (70001, 70002, 70003, 70005);

-- 根据有效订单（已支付/待支付）重算号源剩余量，保证"剩余号 = 总量 - 已占号"，可安全重复执行。
UPDATE schedule_slot s
SET s.remaining_quota = s.total_quota - (
    SELECT COUNT(*) FROM registration_order o
    WHERE o.slot_id = s.id AND o.status IN ('PAID', 'PENDING_PAYMENT')
);

-- 导入后快速确认数据量（无需修改数据）：
SELECT 'department' AS entity, COUNT(*) AS total FROM department WHERE deleted = 0
UNION ALL SELECT 'doctor', COUNT(*) FROM doctor WHERE deleted = 0
UNION ALL SELECT 'schedule_rule', COUNT(*) FROM schedule_rule WHERE deleted = 0
UNION ALL SELECT 'schedule_slot_next_7_days', COUNT(*) FROM schedule_slot WHERE visit_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 6 DAY)
UNION ALL SELECT 'patient_contact', COUNT(*) FROM patient_contact WHERE deleted = 0
UNION ALL SELECT 'registration_order', COUNT(*) FROM registration_order
UNION ALL SELECT 'user', COUNT(*) FROM sys_user WHERE deleted = 0;
