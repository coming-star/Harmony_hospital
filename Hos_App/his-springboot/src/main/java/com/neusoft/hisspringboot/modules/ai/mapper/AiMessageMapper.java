package com.neusoft.hisspringboot.modules.ai.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neusoft.hisspringboot.modules.ai.entity.AiMessage;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AiMessageMapper extends BaseMapper<AiMessage> {
}
