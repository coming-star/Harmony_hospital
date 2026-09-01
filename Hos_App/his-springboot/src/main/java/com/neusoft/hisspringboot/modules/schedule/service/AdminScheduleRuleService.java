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

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminScheduleRuleService {

    private static final String[] WEEKDAY_LABELS = {"周一", "周二", "周三", "周四", "周五", "周六", "周日"};
    private static final String PERIOD_MORNING = "MORNING";
    private static final String PERIOD_AFTERNOON = "AFTERNOON";

    private final ScheduleRuleMapper scheduleRuleMapper;
    private final ScheduleSlotMapper scheduleSlotMapper;

    public PageResult<ScheduleRule> list(String ruleName, int page, int size) {
        Page<ScheduleRule> mpPage = scheduleRuleMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<ScheduleRule>()
                        .like(ruleName != null && !ruleName.isBlank(), ScheduleRule::getRuleName, ruleName)
                        .orderByDesc(ScheduleRule::getCreatedAt)
        );

        mpPage.getRecords().forEach(this::fillComputedFields);
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

    void fillComputedFields(ScheduleRule rule) {
        rule.setRuleCode(buildRuleCode(rule.getWeekdayMask(), rule.getPeriod()));
        rule.setScheduleOverview(buildOverview(rule.getWeekdayMask(), rule.getPeriod()));
    }

    static String buildRuleCode(Integer weekdayMask, String period) {
        if (weekdayMask == null) weekdayMask = 0;
        int periodCode = switch (period) {
            case PERIOD_MORNING -> 0b10;
            case PERIOD_AFTERNOON -> 0b01;
            case "FULL" -> 0b11;
            default -> 0b00;
        };
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 7; i++) {
            boolean hasDay = (weekdayMask >> i & 1) == 1;
            int code = hasDay ? periodCode : 0;
            sb.append((code >> 1) & 1).append(code & 1);
        }
        return sb.toString();
    }

    static List<String> buildOverview(Integer weekdayMask, String period) {
        List<String> result = new ArrayList<>();
        if (weekdayMask == null) return result;
        String periodLabel = switch (period) {
            case PERIOD_MORNING -> "上午";
            case PERIOD_AFTERNOON -> "下午";
            case "FULL" -> "全天";
            default -> "";
        };
        for (int i = 0; i < 7; i++) {
            if (((weekdayMask >> i) & 1) == 1) {
                result.add(WEEKDAY_LABELS[i] + periodLabel);
            }
        }
        return result;
    }
}
