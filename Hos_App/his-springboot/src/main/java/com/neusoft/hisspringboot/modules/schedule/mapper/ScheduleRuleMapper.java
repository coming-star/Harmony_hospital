package com.neusoft.hisspringboot.modules.schedule.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleRule;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ScheduleRuleMapper extends BaseMapper<ScheduleRule> {
}
