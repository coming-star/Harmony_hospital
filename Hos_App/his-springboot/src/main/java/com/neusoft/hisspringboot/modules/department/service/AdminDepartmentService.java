package com.neusoft.hisspringboot.modules.department.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.department.entity.Department;
import com.neusoft.hisspringboot.modules.department.mapper.DepartmentMapper;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorMapper;
import com.neusoft.hisspringboot.modules.doctor.entity.Doctor;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class AdminDepartmentService {

    private final DepartmentMapper departmentMapper;
    private final DoctorMapper doctorMapper;

    public PageResult<Department> list(String name, String departmentType, int page, int size) {
        Page<Department> mpPage = departmentMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<Department>()
                        .like(name != null && !name.isBlank(), Department::getName, name)
                        .eq(departmentType != null && !departmentType.isBlank(), Department::getDepartmentType, departmentType)
                        .orderByAsc(Department::getSortNo)
        );

        return PageResult.of(mpPage.getRecords(), mpPage.getTotal(), page, size);
    }

    public Long create(Department department) {
        ensureCodeAvailable(department.getCode(), null);
        department.setId(null);
        department.setEnabled(department.getEnabled() == null ? 1 : department.getEnabled());
        departmentMapper.insert(department);
        return department.getId();
    }

    public void update(Long id, Department department) {
        getOrThrow(id);
        ensureCodeAvailable(department.getCode(), id);
        department.setId(id);
        departmentMapper.updateById(department);
    }

    public void toggleStatus(Long id, Integer enabled) {
        Department department = getOrThrow(id);
        department.setEnabled(enabled);
        departmentMapper.updateById(department);
    }

    public void delete(Long id) {
        getOrThrow(id);

        Long doctorCount = doctorMapper.selectCount(
                new LambdaQueryWrapper<Doctor>().eq(Doctor::getDepartmentId, id)
        );

        if (doctorCount > 0) {
            throw new BusinessException(ErrorCode.REFERENCED_BY_OTHER_RECORD);
        }

        departmentMapper.deleteById(id);
    }

    private void ensureCodeAvailable(String code, Long excludeId) {
        Long count = departmentMapper.selectCount(
                new LambdaQueryWrapper<Department>()
                        .eq(Department::getCode, code)
                        .ne(excludeId != null, Department::getId, excludeId)
        );

        if (count > 0) {
            throw new BusinessException(ErrorCode.CODE_ALREADY_EXISTS);
        }
    }

    private Department getOrThrow(Long id) {
        Department department = departmentMapper.selectById(id);

        if (department == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "科室不存在");
        }

        return department;
    }
}
