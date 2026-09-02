package com.neusoft.hisspringboot.modules.department.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.RedisCacheUtil;
import com.neusoft.hisspringboot.modules.department.entity.Department;
import com.neusoft.hisspringboot.modules.department.mapper.DepartmentMapper;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorMapper;
import com.neusoft.hisspringboot.modules.doctor.entity.Doctor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdminDepartmentService {

    private static final String DEPT_TREE_CACHE_KEY = "his:cache:deptTree:all";
    private static final String SLOT_QUERY_CACHE_PREFIX = "his:cache:slotQuery:";

    private final DepartmentMapper departmentMapper;
    private final DoctorMapper doctorMapper;
    private final RedisCacheUtil redisCacheUtil;

    private void evictDeptTreeCache() {
        redisCacheUtil.delete(DEPT_TREE_CACHE_KEY);
        log.info("已清除科室树缓存: {}", DEPT_TREE_CACHE_KEY);
    }

    /** 科室结构/状态变化后，号源缓存也需要清（比如停用了心血管内科，该科室的号就不能约了） */
    private void evictSlotCache() {
        redisCacheUtil.deleteByPrefix(SLOT_QUERY_CACHE_PREFIX);
    }

    public PageResult<Department> list(String name, String departmentType, Long parentId, Boolean excludeRoot, int page, int size) {
        boolean effectiveExcludeRoot = !Boolean.FALSE.equals(excludeRoot);

        Page<Department> mpPage = departmentMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<Department>()
                        .like(name != null && !name.isBlank(), Department::getName, name)
                        .eq(departmentType != null && !departmentType.isBlank(), Department::getDepartmentType, departmentType)
                        .eq(parentId != null, Department::getParentId, parentId)
                        .ne(effectiveExcludeRoot, Department::getParentId, 0)
                        .orderByAsc(Department::getSortNo)
        );

        List<Department> records = mpPage.getRecords();
        fillParentNames(records);

        return PageResult.of(records, mpPage.getTotal(), page, size);
    }

    private void fillParentNames(List<Department> departments) {
        if (departments == null || departments.isEmpty()) return;

        List<Long> parentIds = departments.stream()
                .map(Department::getParentId)
                .filter(id -> id != null && id != 0)
                .distinct()
                .collect(Collectors.toList());

        if (parentIds.isEmpty()) return;

        Map<Long, String> parentNameMap = departmentMapper.selectBatchIds(parentIds).stream()
                .collect(Collectors.toMap(Department::getId, Department::getName, (a, b) -> a));

        for (Department dept : departments) {
            if (dept.getParentId() != null && dept.getParentId() != 0) {
                dept.setParentName(parentNameMap.getOrDefault(dept.getParentId(), ""));
            }
        }
    }

    public Long create(Department department) {
        ensureCodeAvailable(department.getCode(), null);
        department.setId(null);
        department.setEnabled(department.getEnabled() == null ? 1 : department.getEnabled());
        departmentMapper.insert(department);
        evictDeptTreeCache();
        evictSlotCache();
        return department.getId();
    }

    public void update(Long id, Department department) {
        Department existing = getOrThrow(id);
        if (existing.getParentId() != null && existing.getParentId() != 0
                && department.getParentId() != null && department.getParentId() == 0) {
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION, "二级科室不能降级为一级科室");
        }
        ensureCodeAvailable(department.getCode(), id);
        department.setId(id);
        departmentMapper.updateById(department);
        evictDeptTreeCache();
        evictSlotCache();
    }

    public void toggleStatus(Long id, Integer enabled) {
        Department department = getOrThrow(id);
        department.setEnabled(enabled);
        departmentMapper.updateById(department);
        evictDeptTreeCache();
        evictSlotCache();
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
        evictDeptTreeCache();
        evictSlotCache();
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
