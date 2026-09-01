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
  (id, name, department_id, title, avatar_url, introduction, enabled)
VALUES
  (4001, '陈明远', 2101, '主任医师', NULL, '从事心血管内科临床与教学工作二十余年，擅长高血压、冠心病及心律失常管理。', 1),
  (4002, '周宁', 2101, '副主任医师', NULL, '擅长心血管常见病诊治及慢病随访。', 1),
  (4003, '赵安然', 2102, '主任医师', NULL, '擅长脑血管疾病、头痛眩晕与睡眠障碍诊治。', 1),
  (4004, '孙悦', 2103, '主治医师', NULL, '擅长胃肠道疾病、脂肪肝及消化不良诊疗。', 1),
  (4005, '何志诚', 2104, '副主任医师', NULL, '擅长慢性咳嗽、哮喘及呼吸道感染诊疗。', 1),
  (4006, '吴清雅', 2201, '主任医师', NULL, '擅长甲状腺、乳腺及胃肠外科常见疾病。', 1),
  (4007, '林峰', 2202, '副主任医师', NULL, '擅长关节运动损伤、骨折康复及脊柱退变性疾病。', 1),
  (4008, '许星河', 2302, '主治医师', NULL, '擅长儿童呼吸道、消化道常见病和儿童保健。', 1),
  (4009, '唐静', 2301, '副主任医师', NULL, '擅长妇科炎症、月经异常及妇科常见疾病诊疗。', 1),
  (4010, '高文博', 2401, '主治医师', NULL, '擅长中医内科常见病辨证调理和亚健康管理。', 1);

INSERT IGNORE INTO doctor_registration_level (id, doctor_id, level_id, enabled)
VALUES
  (4101, 4001, 3003, 1), (4102, 4002, 3002, 1), (4103, 4003, 3003, 1),
  (4104, 4004, 3001, 1), (4105, 4005, 3002, 1), (4106, 4006, 3003, 1),
  (4107, 4007, 3002, 1), (4108, 4008, 3001, 1), (4109, 4009, 3002, 1),
  (4110, 4010, 3001, 1);

-- weekday_mask：31 表示周一至周五；127 表示每天。slots_json 是管理后台编辑的原始规则。
INSERT IGNORE INTO schedule_rule
  (id, doctor_id, level_id, rule_name, weekday_mask, period, slots_json, effective_start, effective_end, enabled)
VALUES
  (5001, 4001, 3003, '陈明远：周一三五上午主任号', 21, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','08:00','end','08:30','quota',4), JSON_OBJECT('start','08:30','end','09:00','quota',4)), CURDATE(), NULL, 1),
  (5002, 4002, 3002, '周宁：工作日上午专家号', 31, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','09:00','end','09:30','quota',6), JSON_OBJECT('start','09:30','end','10:00','quota',6)), CURDATE(), NULL, 1),
  (5003, 4003, 3003, '赵安然：周二四六下午主任号', 42, 'AFTERNOON', JSON_ARRAY(JSON_OBJECT('start','14:00','end','14:30','quota',4), JSON_OBJECT('start','14:30','end','15:00','quota',4)), CURDATE(), NULL, 1),
  (5004, 4004, 3001, '孙悦：工作日下午普通号', 31, 'AFTERNOON', JSON_ARRAY(JSON_OBJECT('start','14:00','end','14:30','quota',10), JSON_OBJECT('start','14:30','end','15:00','quota',10)), CURDATE(), NULL, 1),
  (5005, 4005, 3002, '何志诚：周一至周六上午专家号', 63, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','08:30','end','09:00','quota',6), JSON_OBJECT('start','09:00','end','09:30','quota',6)), CURDATE(), NULL, 1),
  (5006, 4006, 3003, '吴清雅：周二四上午主任号', 10, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','08:00','end','08:30','quota',4), JSON_OBJECT('start','08:30','end','09:00','quota',4)), CURDATE(), NULL, 1),
  (5007, 4007, 3002, '林峰：工作日下午专家号', 31, 'AFTERNOON', JSON_ARRAY(JSON_OBJECT('start','15:00','end','15:30','quota',6), JSON_OBJECT('start','15:30','end','16:00','quota',6)), CURDATE(), NULL, 1),
  (5008, 4008, 3001, '许星河：每天上午普通号', 127, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','09:00','end','09:30','quota',10), JSON_OBJECT('start','09:30','end','10:00','quota',10)), CURDATE(), NULL, 1),
  (5009, 4009, 3002, '唐静：工作日上午专家号', 31, 'MORNING', JSON_ARRAY(JSON_OBJECT('start','10:00','end','10:30','quota',6), JSON_OBJECT('start','10:30','end','11:00','quota',6)), CURDATE(), NULL, 1),
  (5010, 4010, 3001, '高文博：周一至周六下午普通号', 63, 'AFTERNOON', JSON_ARRAY(JSON_OBJECT('start','15:00','end','15:30','quota',8), JSON_OBJECT('start','15:30','end','16:00','quota',8)), CURDATE(), NULL, 1);

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

-- 导入后快速确认数据量（无需修改数据）：
SELECT 'department' AS entity, COUNT(*) AS total FROM department WHERE deleted = 0
UNION ALL SELECT 'doctor', COUNT(*) FROM doctor WHERE deleted = 0
UNION ALL SELECT 'schedule_rule', COUNT(*) FROM schedule_rule WHERE deleted = 0
UNION ALL SELECT 'schedule_slot_next_7_days', COUNT(*) FROM schedule_slot WHERE visit_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 6 DAY)
UNION ALL SELECT 'user', COUNT(*) FROM sys_user WHERE deleted = 0;
