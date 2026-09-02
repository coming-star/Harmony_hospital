package com.neusoft.hisspringboot.modules.schedule.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleRule;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleSlot;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleRuleMapper;
import com.neusoft.hisspringboot.modules.schedule.mapper.ScheduleSlotMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class AdminScheduleRuleService {

    private final ScheduleRuleMapper scheduleRuleMapper;
    private final ScheduleSlotMapper scheduleSlotMapper;

    public PageResult<ScheduleRule> list(int page, int size) {
        Page<ScheduleRule> mpPage = scheduleRuleMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<ScheduleRule>().orderByDesc(ScheduleRule::getCreatedAt)
        );

        return PageResult.of(mpPage.getRecords(), mpPage.getTotal(), page, size);
    }

    public Long create(ScheduleRule rule) {
        rule.setId(null);
        rule.setEnabled(rule.getEnabled() == null ? 1 : rule.getEnabled());
        scheduleRuleMapper.insert(rule);
        return rule.getId();
    }

    public void update(Long id, ScheduleRule rule) {
        getOrThrow(id);
        rule.setId(id);
        scheduleRuleMapper.updateById(rule);
    }

    public void toggleStatus(Long id, Integer enabled) {
        ScheduleRule rule = getOrThrow(id);
        rule.setEnabled(enabled);
        scheduleRuleMapper.updateById(rule);
    }

    public void delete(Long id) {
        getOrThrow(id);

        Long slotCount = scheduleSlotMapper.selectCount(
                new LambdaQueryWrapper<ScheduleSlot>().eq(ScheduleSlot::getScheduleRuleId, id)
        );

        if (slotCount > 0) {
            throw new BusinessException(ErrorCode.REFERENCED_BY_OTHER_RECORD);
        }

        scheduleRuleMapper.deleteById(id);
    }

    private ScheduleRule getOrThrow(Long id) {
        ScheduleRule rule = scheduleRuleMapper.selectById(id);

        if (rule == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "排班规则不存在");
        }

        return rule;
    }
}
