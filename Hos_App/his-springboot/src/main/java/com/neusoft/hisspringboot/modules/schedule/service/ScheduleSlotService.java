package com.neusoft.hisspringboot.modules.schedule.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neusoft.hisspringboot.modules.doctor.entity.Doctor;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorMapper;
import com.neusoft.hisspringboot.modules.level.entity.RegistrationLevel;
import com.neusoft.hisspringboot.modules.level.mapper.RegistrationLevelMapper;
import com.neusoft.hisspringboot.modules.schedule.dto.SlotSummary;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleSlot;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleSlotMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ScheduleSlotService {

    private static final String STATUS_OPEN = "OPEN";

    private final ScheduleSlotMapper scheduleSlotMapper;
    private final DoctorMapper doctorMapper;
    private final RegistrationLevelMapper registrationLevelMapper;

    @Cacheable(value = "slotQuery",
            key = "#departmentId + '_' + #date + '_' + (#levelId != null ? #levelId : 'all')",
            unless = "#result == null || #result.isEmpty()")
    public List<SlotSummary> query(Long departmentId, LocalDate date, Long levelId) {
        log.info("查询号源（未命中缓存）: dept={}, date={}, level={}", departmentId, date, levelId);
        List<ScheduleSlot> slots = scheduleSlotMapper.selectList(
                new LambdaQueryWrapper<ScheduleSlot>()
                        .eq(ScheduleSlot::getDepartmentId, departmentId)
                        .eq(ScheduleSlot::getVisitDate, date)
                        .eq(ScheduleSlot::getStatus, STATUS_OPEN)
                        .gt(ScheduleSlot::getRemainingQuota, 0)
                        .eq(levelId != null, ScheduleSlot::getLevelId, levelId)
                        .orderByAsc(ScheduleSlot::getDoctorId)
                        .orderByAsc(ScheduleSlot::getStartTime)
        );

        if (slots.isEmpty()) {
            return List.of();
        }

        Map<Long, Doctor> doctorById = doctorMapper.selectBatchIds(
                slots.stream().map(ScheduleSlot::getDoctorId).distinct().toList()
        ).stream().collect(Collectors.toMap(Doctor::getId, Function.identity()));

        Map<Long, RegistrationLevel> levelById = registrationLevelMapper.selectBatchIds(
                slots.stream().map(ScheduleSlot::getLevelId).distinct().toList()
        ).stream().collect(Collectors.toMap(RegistrationLevel::getId, Function.identity()));

        return slots.stream()
                .map(slot -> toSummary(slot, doctorById.get(slot.getDoctorId()), levelById.get(slot.getLevelId())))
                .toList();
    }

    private SlotSummary toSummary(ScheduleSlot slot, Doctor doctor, RegistrationLevel level) {
        return new SlotSummary(
                slot.getId(),
                slot.getDoctorId(),
                doctor == null ? null : doctor.getName(),
                doctor == null ? null : doctor.getAvatarUrl(),
                slot.getDepartmentId(),
                slot.getLevelId(),
                level == null ? null : level.getName(),
                level == null ? null : level.getFeeFen(),
                slot.getVisitDate(),
                slot.getStartTime(),
                slot.getEndTime(),
                slot.getRemainingQuota()
        );
    }
}
