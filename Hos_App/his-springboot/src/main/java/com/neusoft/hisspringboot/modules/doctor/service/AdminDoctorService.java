package com.neusoft.hisspringboot.modules.doctor.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.RedisCacheUtil;
import com.neusoft.hisspringboot.modules.department.entity.Department;
import com.neusoft.hisspringboot.modules.department.mapper.DepartmentMapper;
import com.neusoft.hisspringboot.modules.doctor.dto.AdminDoctorRequest;
import com.neusoft.hisspringboot.modules.doctor.dto.AdminDoctorResponse;
import com.neusoft.hisspringboot.modules.doctor.dto.DoctorScheduleRuleBrief;
import com.neusoft.hisspringboot.modules.doctor.entity.Doctor;
import com.neusoft.hisspringboot.modules.doctor.entity.DoctorRegistrationLevel;
import com.neusoft.hisspringboot.modules.doctor.entity.DoctorScheduleRule;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorMapper;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorRegistrationLevelMapper;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorScheduleRuleMapper;
import com.neusoft.hisspringboot.modules.level.entity.RegistrationLevel;
import com.neusoft.hisspringboot.modules.level.mapper.RegistrationLevelMapper;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleRule;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleSlot;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleRuleMapper;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleSlotMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminDoctorService {

    /** 号源查询缓存前缀：与 ScheduleSlotService / OrderService 保持一致 */
    private static final String SLOT_QUERY_CACHE_PREFIX = "his:cache:slotQuery:";

    private final DoctorMapper doctorMapper;
    private final DepartmentMapper departmentMapper;
    private final DoctorRegistrationLevelMapper doctorRegistrationLevelMapper;
    private final DoctorScheduleRuleMapper doctorScheduleRuleMapper;
    private final ScheduleRuleMapper scheduleRuleMapper;
    private final ScheduleSlotMapper scheduleSlotMapper;
    private final RegistrationLevelMapper registrationLevelMapper;
    private final RedisCacheUtil redisCacheUtil;

    /** 医生变动（增/改/停用/删）后，清空全部号源查询缓存，避免患者端看到过期的医生排班数据 */
    private void evictSlotCache() {
        redisCacheUtil.deleteByPrefix(SLOT_QUERY_CACHE_PREFIX);
    }

    public PageResult<AdminDoctorResponse> list(String name, Long departmentId, int page, int size) {
        List<Long> effectiveDeptIds = null;
        if (departmentId != null) {
            Department selected = departmentMapper.selectById(departmentId);
            if (selected != null && (selected.getParentId() == null || selected.getParentId() == 0)) {
                effectiveDeptIds = departmentMapper.selectList(
                        new LambdaQueryWrapper<Department>().eq(Department::getParentId, departmentId)
                ).stream().map(Department::getId).collect(Collectors.toList());
                if (effectiveDeptIds.isEmpty()) {
                    effectiveDeptIds = List.of(-1L);
                }
            } else {
                effectiveDeptIds = new ArrayList<>();
                effectiveDeptIds.add(departmentId);
            }
        }

        Page<Doctor> mpPage = doctorMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<Doctor>()
                        .like(name != null && !name.isBlank(), Doctor::getName, name)
                        .in(effectiveDeptIds != null, Doctor::getDepartmentId, effectiveDeptIds)
                        .orderByDesc(Doctor::getCreatedAt)
        );

        List<Doctor> doctors = mpPage.getRecords();

        if (doctors.isEmpty()) {
            return PageResult.of(List.of(), mpPage.getTotal(), page, size);
        }

        List<Long> doctorIds = doctors.stream().map(Doctor::getId).toList();
        Map<Long, String> deptNameById = departmentMapper.selectBatchIds(
                doctors.stream().map(Doctor::getDepartmentId).distinct().toList()
        ).stream().collect(Collectors.toMap(Department::getId, Department::getName, (a, b) -> a));
        Map<Long, List<Long>> levelIdsByDoctorId = doctorRegistrationLevelMapper.selectList(
                new LambdaQueryWrapper<DoctorRegistrationLevel>().in(DoctorRegistrationLevel::getDoctorId, doctorIds)
        ).stream().collect(Collectors.groupingBy(
                DoctorRegistrationLevel::getDoctorId,
                Collectors.mapping(DoctorRegistrationLevel::getLevelId, Collectors.toList())
        ));

        List<DoctorScheduleRule> doctorRuleRelations = doctorScheduleRuleMapper.selectList(
                new LambdaQueryWrapper<DoctorScheduleRule>().in(DoctorScheduleRule::getDoctorId, doctorIds)
        );

        Map<Long, List<Long>> ruleIdsByDoctorId = doctorRuleRelations.stream()
                .collect(Collectors.groupingBy(
                        DoctorScheduleRule::getDoctorId,
                        Collectors.mapping(DoctorScheduleRule::getScheduleRuleId, Collectors.toList())
                ));

        List<Long> allRuleIds = doctorRuleRelations.stream()
                .map(DoctorScheduleRule::getScheduleRuleId).distinct().toList();

        Map<Long, ScheduleRule> ruleById = allRuleIds.isEmpty()
                ? Map.of()
                : scheduleRuleMapper.selectBatchIds(allRuleIds).stream()
                        .collect(Collectors.toMap(ScheduleRule::getId, r -> r));

        Map<Long, String> levelNameById = allRuleIds.isEmpty()
                ? Map.of()
                : registrationLevelMapper.selectBatchIds(
                        ruleById.values().stream().map(ScheduleRule::getLevelId).distinct().toList()
                ).stream().collect(Collectors.toMap(RegistrationLevel::getId, RegistrationLevel::getName));

        Map<Long, List<DoctorScheduleRuleBrief>> scheduleRulesByDoctorId = doctorIds.stream()
                .collect(Collectors.toMap(
                        did -> did,
                        did -> ruleIdsByDoctorId.getOrDefault(did, List.of()).stream()
                                .map(ruleById::get).filter(r -> r != null)
                                .map(rule -> new DoctorScheduleRuleBrief(
                                        rule.getId(),
                                        rule.getLevelId(),
                                        levelNameById.get(rule.getLevelId()),
                                        rule.getRuleName(),
                                        rule.getWeekdayMask(),
                                        rule.getPeriod()
                                ))
                                .toList()
                ));

        List<AdminDoctorResponse> records = doctors.stream()
                .map(doctor -> toResponse(
                        doctor,
                        deptNameById.getOrDefault(doctor.getDepartmentId(), ""),
                        levelIdsByDoctorId.getOrDefault(doctor.getId(), List.of()),
                        scheduleRulesByDoctorId.getOrDefault(doctor.getId(), List.of())
                ))
                .toList();

        return PageResult.of(records, mpPage.getTotal(), page, size);
    }

    @Transactional
    public Long create(AdminDoctorRequest request) {
        Doctor doctor = new Doctor();
        doctor.setName(request.name());
        doctor.setDepartmentId(request.departmentId());
        doctor.setTitle(request.title());
        doctor.setIntroduction(request.introduction());
        doctor.setEnabled(1);
        doctorMapper.insert(doctor);

        replaceLevels(doctor.getId(), request.levelIds());
        replaceScheduleRules(doctor.getId(), request.scheduleRuleIds());
        evictSlotCache();

        return doctor.getId();
    }

    @Transactional
    public void update(Long id, AdminDoctorRequest request) {
        Doctor doctor = getOrThrow(id);
        doctor.setName(request.name());
        doctor.setDepartmentId(request.departmentId());
        doctor.setTitle(request.title());
        doctor.setIntroduction(request.introduction());
        doctorMapper.updateById(doctor);

        replaceLevels(id, request.levelIds());
        replaceScheduleRules(id, request.scheduleRuleIds());
        evictSlotCache();
    }

    public void toggleStatus(Long id, Integer enabled) {
        Doctor doctor = getOrThrow(id);
        doctor.setEnabled(enabled);
        doctorMapper.updateById(doctor);
        evictSlotCache();
    }

    public void delete(Long id) {
        getOrThrow(id);

        Long slotCount = scheduleSlotMapper.selectCount(
                new LambdaQueryWrapper<ScheduleSlot>().eq(ScheduleSlot::getDoctorId, id)
        );

        if (slotCount > 0) {
            throw new BusinessException(ErrorCode.REFERENCED_BY_OTHER_RECORD);
        }

        doctorScheduleRuleMapper.delete(
                new LambdaQueryWrapper<DoctorScheduleRule>().eq(DoctorScheduleRule::getDoctorId, id)
        );

        doctorMapper.deleteById(id);
        evictSlotCache();
    }

    private void replaceLevels(Long doctorId, List<Long> levelIds) {
        doctorRegistrationLevelMapper.delete(
                new LambdaQueryWrapper<DoctorRegistrationLevel>().eq(DoctorRegistrationLevel::getDoctorId, doctorId)
        );

        if (levelIds == null || levelIds.isEmpty()) {
            return;
        }

        for (Long levelId : levelIds) {
            DoctorRegistrationLevel relation = new DoctorRegistrationLevel();
            relation.setDoctorId(doctorId);
            relation.setLevelId(levelId);
            relation.setEnabled(1);
            doctorRegistrationLevelMapper.insert(relation);
        }
    }

    private void replaceScheduleRules(Long doctorId, List<Long> ruleIds) {
        doctorScheduleRuleMapper.delete(
                new LambdaQueryWrapper<DoctorScheduleRule>().eq(DoctorScheduleRule::getDoctorId, doctorId)
        );

        if (ruleIds == null || ruleIds.isEmpty()) {
            return;
        }

        List<ScheduleRule> validRules = scheduleRuleMapper.selectBatchIds(ruleIds);
        for (ScheduleRule rule : validRules) {
            DoctorScheduleRule rel = new DoctorScheduleRule();
            rel.setDoctorId(doctorId);
            rel.setScheduleRuleId(rule.getId());
            doctorScheduleRuleMapper.insert(rel);
        }
    }

    private Doctor getOrThrow(Long id) {
        Doctor doctor = doctorMapper.selectById(id);

        if (doctor == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "医生不存在");
        }

        return doctor;
    }

    private AdminDoctorResponse toResponse(
            Doctor doctor,
            String departmentName,
            List<Long> levelIds,
            List<DoctorScheduleRuleBrief> scheduleRules
    ) {
        return new AdminDoctorResponse(
                doctor.getId(),
                doctor.getName(),
                doctor.getDepartmentId(),
                departmentName,
                doctor.getTitle(),
                doctor.getIntroduction(),
                doctor.getEnabled(),
                levelIds,
                scheduleRules
        );
    }
}
