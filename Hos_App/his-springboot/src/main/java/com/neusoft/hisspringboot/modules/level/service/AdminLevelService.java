package com.neusoft.hisspringboot.modules.level.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.doctor.entity.DoctorRegistrationLevel;
import com.neusoft.hisspringboot.modules.doctor.mapper.DoctorRegistrationLevelMapper;
import com.neusoft.hisspringboot.modules.level.entity.RegistrationLevel;
import com.neusoft.hisspringboot.modules.level.mapper.RegistrationLevelMapper;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleRule;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleRuleMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class AdminLevelService {

    private final RegistrationLevelMapper registrationLevelMapper;
    private final DoctorRegistrationLevelMapper doctorRegistrationLevelMapper;
    private final ScheduleRuleMapper scheduleRuleMapper;

    public PageResult<RegistrationLevel> list(int page, int size) {
        Page<RegistrationLevel> mpPage = registrationLevelMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<RegistrationLevel>().orderByAsc(RegistrationLevel::getSortNo)
        );

        return PageResult.of(mpPage.getRecords(), mpPage.getTotal(), page, size);
    }

    public Long create(RegistrationLevel level) {
        ensureCodeAvailable(level.getCode(), null);
        level.setId(null);
        level.setEnabled(level.getEnabled() == null ? 1 : level.getEnabled());
        registrationLevelMapper.insert(level);
        return level.getId();
    }

    public void update(Long id, RegistrationLevel level) {
        getOrThrow(id);
        ensureCodeAvailable(level.getCode(), id);
        level.setId(id);
        registrationLevelMapper.updateById(level);
    }

    public void toggleStatus(Long id, Integer enabled) {
        RegistrationLevel level = getOrThrow(id);
        level.setEnabled(enabled);
        registrationLevelMapper.updateById(level);
    }

    public void delete(Long id) {
        getOrThrow(id);

        Long doctorRefCount = doctorRegistrationLevelMapper.selectCount(
                new LambdaQueryWrapper<DoctorRegistrationLevel>().eq(DoctorRegistrationLevel::getLevelId, id)
        );
        Long ruleRefCount = scheduleRuleMapper.selectCount(
                new LambdaQueryWrapper<ScheduleRule>().eq(ScheduleRule::getLevelId, id)
        );

        if (doctorRefCount > 0 || ruleRefCount > 0) {
            throw new BusinessException(ErrorCode.REFERENCED_BY_OTHER_RECORD);
        }

        registrationLevelMapper.deleteById(id);
    }

    private void ensureCodeAvailable(String code, Long excludeId) {
        Long count = registrationLevelMapper.selectCount(
                new LambdaQueryWrapper<RegistrationLevel>()
                        .eq(RegistrationLevel::getCode, code)
                        .ne(excludeId != null, RegistrationLevel::getId, excludeId)
        );

        if (count > 0) {
            throw new BusinessException(ErrorCode.CODE_ALREADY_EXISTS);
        }
    }

    private RegistrationLevel getOrThrow(Long id) {
        RegistrationLevel level = registrationLevelMapper.selectById(id);

        if (level == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "挂号级别不存在");
        }

        return level;
    }
}
