package com.neusoft.hisspringboot.modules.department.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neusoft.hisspringboot.modules.department.dto.DepartmentTreeNode;
import com.neusoft.hisspringboot.modules.department.entity.Department;
import com.neusoft.hisspringboot.modules.department.mapper.DepartmentMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class DepartmentService {

    private static final Long ROOT_PARENT_ID = 0L;

    private final DepartmentMapper departmentMapper;

    @Cacheable(value = "deptTree", key = "'all'", unless = "#result == null || #result.isEmpty()")
    public List<DepartmentTreeNode> tree() {
        log.info("查询科室树（未命中缓存）");
        List<Department> departments = departmentMapper.selectList(
                new LambdaQueryWrapper<Department>()
                        .eq(Department::getEnabled, 1)
                        .orderByAsc(Department::getSortNo)
        );

        Map<Long, List<Department>> byParentId = departments.stream()
                .collect(Collectors.groupingBy(Department::getParentId));

        return buildChildren(ROOT_PARENT_ID, byParentId);
    }

    private List<DepartmentTreeNode> buildChildren(
            Long parentId,
            Map<Long, List<Department>> byParentId
    ) {
        return byParentId.getOrDefault(parentId, List.of()).stream()
                .map(department -> new DepartmentTreeNode(
                        department.getId(),
                        department.getCode(),
                        department.getName(),
                        department.getDescription(),
                        department.getSortNo(),
                        buildChildren(department.getId(), byParentId)
                ))
                .toList();
    }
}
