package com.neusoft.hisspringboot.modules.contact.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.modules.contact.dto.ContactRequest;
import com.neusoft.hisspringboot.modules.contact.entity.PatientContact;
import com.neusoft.hisspringboot.modules.contact.mapper.PatientContactMapper;
import com.neusoft.hisspringboot.modules.order.entity.RegistrationOrder;
import com.neusoft.hisspringboot.modules.order.mapper.RegistrationOrderMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

/**
 * 患者端就诊人管理：查询我的就诊人列表、新增、修改、删除。
 * 所有方法都强制以 token 中的 userId 为归属边界，只能操作自己账号下的就诊人（防越权）。
 */
@Service
@RequiredArgsConstructor
public class ContactService {

    /** 有进行中订单（待支付/已支付）的就诊人不允许删除 */
    private static final List<String> ACTIVE_ORDER_STATUSES = List.of("PENDING_PAYMENT", "PAID");

    private final PatientContactMapper patientContactMapper;
    private final RegistrationOrderMapper registrationOrderMapper;

    /** 查询当前登录账号绑定的全部就诊人 */
    public List<PatientContact> list(Long userId) {
        return patientContactMapper.selectList(
                new LambdaQueryWrapper<PatientContact>()
                        .eq(PatientContact::getUserId, userId)
                        .orderByDesc(PatientContact::getCreatedAt)
        );
    }

    /** 新增就诊人 */
    public Long create(Long userId, ContactRequest request) {
        PatientContact contact = new PatientContact();
        contact.setUserId(userId);
        contact.setName(request.name());
        contact.setPhone(request.phone());
        contact.setRelation(normalizeRelation(request.relation()));
        patientContactMapper.insert(contact);
        return contact.getId();
    }

    /** 修改就诊人（只能改自己的） */
    public void update(Long userId, Long id, ContactRequest request) {
        PatientContact contact = getOwnedOrThrow(userId, id);
        contact.setName(request.name());
        contact.setPhone(request.phone());
        contact.setRelation(normalizeRelation(request.relation()));
        patientContactMapper.updateById(contact);
    }

    /** 删除就诊人（逻辑删除）；有进行中挂号记录的不允许删 */
    public void delete(Long userId, Long id) {
        getOwnedOrThrow(userId, id);

        Long activeOrderCount = registrationOrderMapper.selectCount(
                new LambdaQueryWrapper<RegistrationOrder>()
                        .eq(RegistrationOrder::getContactId, id)
                        .in(RegistrationOrder::getStatus, ACTIVE_ORDER_STATUSES)
        );
        if (activeOrderCount > 0) {
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION,
                    "该就诊人有未完成的挂号记录，不能删除");
        }

        patientContactMapper.deleteById(id);
    }

    /** 查出就诊人并校验归属：不存在或不属于当前账号一律 404，不暴露"存在但无权限"的区别 */
    private PatientContact getOwnedOrThrow(Long userId, Long id) {
        PatientContact contact = patientContactMapper.selectOne(
                new LambdaQueryWrapper<PatientContact>()
                        .eq(PatientContact::getId, id)
                        .eq(PatientContact::getUserId, userId)
        );
        if (contact == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "就诊人不存在");
        }
        return contact;
    }

    private String normalizeRelation(String relation) {
        return (relation == null || relation.isBlank()) ? "SELF" : relation;
    }
}
