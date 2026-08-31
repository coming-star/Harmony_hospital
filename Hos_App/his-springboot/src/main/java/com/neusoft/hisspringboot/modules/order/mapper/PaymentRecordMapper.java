package com.neusoft.hisspringboot.modules.order.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neusoft.hisspringboot.modules.order.entity.PaymentRecord;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PaymentRecordMapper extends BaseMapper<PaymentRecord> {
}
