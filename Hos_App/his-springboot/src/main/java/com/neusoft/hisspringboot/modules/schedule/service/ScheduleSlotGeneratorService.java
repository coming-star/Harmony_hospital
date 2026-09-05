package com.neusoft.hisspringboot.modules.schedule.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.neusoft.hisspringboot.common.RedisCacheUtil;
import com.neusoft.hisspringboot.modules.doctor.entity.Doctor;
import com.neusoft.hisspringboot.modules.doctor.entity.DoctorScheduleRule;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorMapper;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorScheduleRuleMapper;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleRule;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleSlot;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleRuleMapper;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleSlotMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 排班号源生成器：把周期性排班规则展开为未来 N 天的具体号源（schedule_slot）。
 * 触发时机：应用启动时、每天 00:10 定时滚动、管理端修改排班规则后。
 * 幂等性：以 uk_slot_doctor_date_time_level 唯一键为准，已存在的"医生+日期+时段+号别"不重复生成。
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ScheduleSlotGeneratorService implements ApplicationRunner {

    /** 每次生成未来多少天的号源窗口 */
    private static final int GENERATE_DAYS = 14;
    private static final String STATUS_OPEN = "OPEN";
    /** 号源查询缓存前缀：生成后统一失效，让患者端下次查询回源 */
    private static final String SLOT_QUERY_CACHE_PREFIX = "his:cache:slotQuery:";

    private final ScheduleRuleMapper scheduleRuleMapper;
    private final DoctorScheduleRuleMapper doctorScheduleRuleMapper;
    private final DoctorMapper doctorMapper;
    private final ScheduleSlotMapper scheduleSlotMapper;
    private final RedisCacheUtil redisCacheUtil;
    private final ObjectMapper objectMapper;

    /** 应用启动即展开未来 14 天，保证种子数据过期后患者端依然有号可挂 */
    @Override
    public void run(ApplicationArguments args) {
        generateNextDays();
    }

    /** 每天 00:10 滚动生成未来 14 天号源 */
    @Scheduled(cron = "0 10 0 * * ?")
    public void dailyGenerate() {
        generateNextDays();
    }

    /** 供管理端修改排班规则后立即重新展开 */
    public void generateNextDays() {
        generateRange(LocalDate.now(), LocalDate.now().plusDays(GENERATE_DAYS - 1L));
    }

    /**
     * 把启用中的排班规则展开为 [start, end] 区间内的具体号源。
     * @return 本次新插入的号源条数
     */
    public int generateRange(LocalDate start, LocalDate end) {
        List<ScheduleRule> rules = scheduleRuleMapper.selectList(
                new LambdaQueryWrapper<ScheduleRule>().eq(ScheduleRule::getEnabled, 1));
        if (rules.isEmpty()) {
            return 0;
        }

        Map<Long, List<Long>> doctorIdsByRule = doctorScheduleRuleMapper.selectList(null).stream()
                .collect(Collectors.groupingBy(
                        DoctorScheduleRule::getScheduleRuleId,
                        Collectors.mapping(DoctorScheduleRule::getDoctorId, Collectors.toList())));

        Map<Long, Doctor> doctorById = doctorMapper.selectList(
                        new LambdaQueryWrapper<Doctor>().eq(Doctor::getEnabled, 1)).stream()
                .collect(Collectors.toMap(Doctor::getId, d -> d));

        int inserted = 0;
        for (ScheduleRule rule : rules) {
            for (Long doctorId : doctorIdsByRule.getOrDefault(rule.getId(), List.of())) {
                Doctor doctor = doctorById.get(doctorId);
                if (doctor == null) {
                    continue;
                }
                inserted += expand(rule, doctor, start, end);
            }
        }

        if (inserted > 0) {
            redisCacheUtil.deleteByPrefix(SLOT_QUERY_CACHE_PREFIX);
        }
        log.info("排班号源生成完成: 区间=[{} ~ {}], 新增 {} 条", start, end, inserted);
        return inserted;
    }

    /** 把一条规则按星期掩码与生效区间展开到某位医生名下 */
    private int expand(ScheduleRule rule, Doctor doctor, LocalDate start, LocalDate end) {
        JsonNode slots;
        try {
            slots = objectMapper.readTree(rule.getSlotsJson());
        } catch (Exception e) {
            log.warn("规则 {} 的 slots_json 解析失败，已跳过: {}", rule.getId(), e.getMessage());
            return 0;
        }

        int count = 0;
        for (LocalDate date = start; !date.isAfter(end); date = date.plusDays(1)) {
            if (!hitWeekday(rule.getWeekdayMask(), date)) {
                continue;
            }
            if (rule.getEffectiveStart() != null && date.isBefore(rule.getEffectiveStart())) {
                continue;
            }
            if (rule.getEffectiveEnd() != null && date.isAfter(rule.getEffectiveEnd())) {
                continue;
            }

            for (JsonNode s : slots) {
                LocalTime startTime = LocalTime.parse(s.path("start").asText());
                LocalTime endTime = LocalTime.parse(s.path("end").asText());
                int quota = s.path("quota").asInt(0);
                if (quota <= 0) {
                    continue;
                }

                Long exists = scheduleSlotMapper.selectCount(
                        new LambdaQueryWrapper<ScheduleSlot>()
                                .eq(ScheduleSlot::getDoctorId, doctor.getId())
                                .eq(ScheduleSlot::getVisitDate, date)
                                .eq(ScheduleSlot::getStartTime, startTime)
                                .eq(ScheduleSlot::getEndTime, endTime)
                                .eq(ScheduleSlot::getLevelId, rule.getLevelId()));
                if (exists > 0) {
                    continue;
                }

                ScheduleSlot slot = new ScheduleSlot();
                slot.setScheduleRuleId(rule.getId());
                slot.setDoctorId(doctor.getId());
                slot.setDepartmentId(doctor.getDepartmentId());
                slot.setLevelId(rule.getLevelId());
                slot.setVisitDate(date);
                slot.setStartTime(startTime);
                slot.setEndTime(endTime);
                slot.setTotalQuota(quota);
                slot.setRemainingQuota(quota);
                slot.setStatus(STATUS_OPEN);
                slot.setVersion(0);
                try {
                    scheduleSlotMapper.insert(slot);
                    count++;
                } catch (DuplicateKeyException e) {
                    // 并发生成被唯一键拦下，视为已存在，忽略即可
                }
            }
        }
        return count;
    }

    /** weekdayMask 的 bit0-6 依次对应周一至周日 */
    static boolean hitWeekday(Integer weekdayMask, LocalDate date) {
        if (weekdayMask == null || weekdayMask == 0) {
            return false;
        }
        int bit = date.getDayOfWeek().getValue() - 1;
        return ((weekdayMask >> bit) & 1) == 1;
    }
}
