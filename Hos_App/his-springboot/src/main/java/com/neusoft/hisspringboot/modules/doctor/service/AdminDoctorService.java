package com.neusoft.hisspringboot.modules.doctor.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.doctor.dto.AdminDoctorRequest;
import com.neusoft.hisspringboot.modules.doctor.dto.AdminDoctorResponse;
import com.neusoft.hisspringboot.modules.doctor.entity.Doctor;
import com.neusoft.hisspringboot.modules.doctor.entity.DoctorRegistrationLevel;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorMapper;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorRegistrationLevelMapper;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleRule;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleSlot;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleRuleMapper;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleSlotMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminDoctorService {

    private final DoctorMapper doctorMapper;
    private final DoctorRegistrationLevelMapper doctorRegistrationLevelMapper;
    private final ScheduleRuleMapper scheduleRuleMapper;
    private final ScheduleSlotMapper scheduleSlotMapper;

    public PageResult<AdminDoctorResponse> list(String name, Long departmentId, int page, int size) {
        Page<Doctor> mpPage = doctorMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<Doctor>()
                        .like(name != null && !name.isBlank(), Doctor::getName, name)
                        .eq(departmentId != null, Doctor::getDepartmentId, departmentId)
                        .orderByDesc(Doctor::getCreatedAt)
        );

        List<Doctor> doctors = mpPage.getRecords();

        if (doctors.isEmpty()) {
            return PageResult.of(List.of(), mpPage.getTotal(), page, size);
        }

        List<Long> doctorIds = doctors.stream().map(Doctor::getId).toList();
        Map<Long, List<Long>> levelIdsByDoctorId = doctorRegistrationLevelMapper.selectList(
                new LambdaQueryWrapper<DoctorRegistrationLevel>().in(DoctorRegistrationLevel::getDoctorId, doctorIds)
        ).stream().collect(Collectors.groupingBy(
                DoctorRegistrationLevel::getDoctorId,
                Collectors.mapping(DoctorRegistrationLevel::getLevelId, Collectors.toList())
        ));

        List<AdminDoctorResponse> records = doctors.stream()
                .map(doctor -> toResponse(doctor, levelIdsByDoctorId.getOrDefault(doctor.getId(), List.of())))
                .toList();

        return PageResult.of(records, mpPage.getTotal(), page, size);
    }

    @Transactional
    public Long create(AdminDoctorRequest request) {
        Doctor doctor = new Doctor();
        doctor.setName(request.name());
        doctor.setDepartmentId(request.departmentId());
        doctor.setTitle(request.title());
        doctor.setAvatarUrl(request.avatarUrl());
        doctor.setIntroduction(request.introduction());
        doctor.setEnabled(1);
        doctorMapper.insert(doctor);

        replaceLevels(doctor.getId(), request.levelIds());

        return doctor.getId();
    }

    @Transactional
    public void update(Long id, AdminDoctorRequest request) {
        Doctor doctor = getOrThrow(id);
        doctor.setName(request.name());
        doctor.setDepartmentId(request.departmentId());
        doctor.setTitle(request.title());
        doctor.setAvatarUrl(request.avatarUrl());
        doctor.setIntroduction(request.introduction());
        doctorMapper.updateById(doctor);

        replaceLevels(id, request.levelIds());
    }

    public void toggleStatus(Long id, Integer enabled) {
        Doctor doctor = getOrThrow(id);
        doctor.setEnabled(enabled);
        doctorMapper.updateById(doctor);
    }

    public void delete(Long id) {
        getOrThrow(id);

        Long ruleCount = scheduleRuleMapper.selectCount(
                new LambdaQueryWrapper<ScheduleRule>().eq(ScheduleRule::getDoctorId, id)
        );
        Long slotCount = scheduleSlotMapper.selectCount(
                new LambdaQueryWrapper<ScheduleSlot>().eq(ScheduleSlot::getDoctorId, id)
        );

        if (ruleCount > 0 || slotCount > 0) {
            throw new BusinessException(ErrorCode.REFERENCED_BY_OTHER_RECORD);
        }

        doctorMapper.deleteById(id);
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

    private Doctor getOrThrow(Long id) {
        Doctor doctor = doctorMapper.selectById(id);

        if (doctor == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "医生不存在");
        }

        return doctor;
    }

    private AdminDoctorResponse toResponse(Doctor doctor, List<Long> levelIds) {
        return new AdminDoctorResponse(
                doctor.getId(),
                doctor.getName(),
                doctor.getDepartmentId(),
                doctor.getTitle(),
                doctor.getAvatarUrl(),
                doctor.getIntroduction(),
                doctor.getEnabled(),
                levelIds
        );
    }
}
