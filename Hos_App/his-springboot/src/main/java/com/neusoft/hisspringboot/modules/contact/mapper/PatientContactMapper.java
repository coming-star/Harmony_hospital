package com.neusoft.hisspringboot.modules.contact.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neusoft.hisspringboot.modules.contact.entity.PatientContact;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PatientContactMapper extends BaseMapper<PatientContact> {
}
