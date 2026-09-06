package com.neusoft.hisspringboot.modules.notification.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neusoft.hisspringboot.modules.notification.entity.Message;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface MessageMapper extends BaseMapper<Message> {
}
