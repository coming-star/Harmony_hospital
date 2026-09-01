package com.neusoft.hisspringboot.modules.doctor.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neusoft.hisspringboot.modules.department.entity.Department;
import com.neusoft.hisspringboot.modules.department.mapper.DepartmentMapper;
import com.neusoft.hisspringboot.modules.doctor.dto.DoctorDetailResponse;
import com.neusoft.hisspringboot.modules.doctor.dto.DoctorLevelBrief;
import com.neusoft.hisspringboot.modules.doctor.entity.Doctor;
import com.neusoft.hisspringboot.modules.doctor.entity.DoctorRegistrationLevel;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorMapper;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorRegistrationLevelMapper;
import com.neusoft.hisspringboot.modules.level.entity.RegistrationLevel;
import com.neusoft.hisspringboot.modules.level.mapper.RegistrationLevelMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class DoctorService {

    private final DoctorMapper doctorMapper;
    private final DepartmentMapper departmentMapper;
    private final DoctorRegistrationLevelMapper doctorRegistrationLevelMapper;
    private final RegistrationLevelMapper registrationLevelMapper;

    public DoctorDetailResponse getDetail(Long doctorId) {
        Doctor doctor = doctorMapper.selectById(doctorId);

        if (doctor == null || doctor.getEnabled() == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "医生不存在或已下线");
        }

        Department department = departmentMapper.selectById(doctor.getDepartmentId());

        List<DoctorRegistrationLevel> relations = doctorRegistrationLevelMapper.selectList(
                new LambdaQueryWrapper<DoctorRegistrationLevel>()
                        .eq(DoctorRegistrationLevel::getDoctorId, doctorId)
                        .eq(DoctorRegistrationLevel::getEnabled, 1)
        );

        List<Long> levelIds = relations.stream().map(DoctorRegistrationLevel::getLevelId).toList();

        List<DoctorLevelBrief> levels = levelIds.isEmpty()
                ? List.of()
                : registrationLevelMapper.selectBatchIds(levelIds).stream()
                        .filter(level -> level.getEnabled() == 1)
                        .map(level -> new DoctorLevelBrief(
                                level.getId(), level.getCode(), level.getName(), level.getFeeFen()
                        ))
                        .toList();

        return new DoctorDetailResponse(
                doctor.getId(),
                doctor.getName(),
                doctor.getDepartmentId(),
                department == null ? null : department.getName(),
                doctor.getTitle(),
                doctor.getIntroduction(),
                levels
        );
    }
}
