package com.neusoft.hisspringboot.modules.contact.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neusoft.hisspringboot.common.AesGcmUtil;
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
 * 身份证 AES-GCM 加密存储，SHA-256 哈希用于同账号判重，明文不入库不回显。
 */
@Service
@RequiredArgsConstructor
public class ContactService {

    /** 有进行中订单（待支付/已支付）的就诊人不允许删除 */
    private static final List<String> ACTIVE_ORDER_STATUSES = List.of("PENDING_PAYMENT", "PAID");

    private final PatientContactMapper patientContactMapper;
    private final RegistrationOrderMapper registrationOrderMapper;
    private final AesGcmUtil aesGcmUtil;

    /** 查询当前登录账号绑定的全部就诊人（身份证仅返回脱敏值） */
    public List<PatientContact> list(Long userId) {
        List<PatientContact> list = patientContactMapper.selectList(
                new LambdaQueryWrapper<PatientContact>()
                        .eq(PatientContact::getUserId, userId)
                        .orderByDesc(PatientContact::getCreatedAt)
        );
        list.forEach(this::fillMaskedIdCard);
        return list;
    }

    /** 新增就诊人 */
    public Long create(Long userId, ContactRequest request) {
        // 身份证哈希判重：同账号下同一身份证只能绑定一个就诊人
        checkDuplicateIdCard(userId, null, request.idCard());

        PatientContact contact = new PatientContact();
        contact.setUserId(userId);
        contact.setName(request.name());
        contact.setPhone(request.phone());
        contact.setRelation(normalizeRelation(request.relation()));
        setIdCard(contact, request.idCard());
        patientContactMapper.insert(contact);
        return contact.getId();
    }

    /** 修改就诊人（只能改自己的） */
    public void update(Long userId, Long id, ContactRequest request) {
        PatientContact contact = getOwnedOrThrow(userId, id);

        contact.setName(request.name());
        contact.setPhone(request.phone());
        contact.setRelation(normalizeRelation(request.relation()));
        // 身份证：null 表示前端未传该字段 → 保留原值；空串表示主动清除；非空表示更新
        if (request.idCard() != null) {
            checkDuplicateIdCard(userId, id, request.idCard());
            setIdCard(contact, request.idCard());
        }
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

    // ===================== 身份证相关私有方法 =====================

    /** 同账号下身份证哈希判重：排除当前正在编辑的就诊人 */
    private void checkDuplicateIdCard(Long userId, Long excludeId, String idCard) {
        if (idCard == null || idCard.isBlank()) {
            return;
        }
        String hash = AesGcmUtil.sha256(idCard.trim());
        LambdaQueryWrapper<PatientContact> wrapper = new LambdaQueryWrapper<PatientContact>()
                .eq(PatientContact::getUserId, userId)
                .eq(PatientContact::getIdCardHash, hash);
        if (excludeId != null) {
            wrapper.ne(PatientContact::getId, excludeId);
        }
        Long count = patientContactMapper.selectCount(wrapper);
        if (count != null && count > 0) {
            throw new BusinessException(ErrorCode.BUSINESS_RULE_VIOLATION,
                    "该身份证已绑定本账号的其他就诊人");
        }
    }

    /** 加密身份证并填充密文/哈希 */
    private void setIdCard(PatientContact contact, String idCard) {
        if (idCard == null || idCard.isBlank()) {
            contact.setIdCardCipher(null);
            contact.setIdCardHash(null);
            return;
        }
        String plain = idCard.trim();
        contact.setIdCardCipher(aesGcmUtil.encrypt(plain));
        contact.setIdCardHash(AesGcmUtil.sha256(plain));
    }

    /** 用密文解密后填充脱敏展示字段（110***********1234） */
    private void fillMaskedIdCard(PatientContact contact) {
        byte[] cipher = contact.getIdCardCipher();
        if (cipher == null || cipher.length == 0) {
            contact.setIdCardMasked(null);
            return;
        }
        try {
            String plain = aesGcmUtil.decrypt(cipher);
            contact.setIdCardMasked(maskIdCard(plain));
        } catch (Exception e) {
            contact.setIdCardMasked(null);
        }
    }

    /** 身份证脱敏：保留前 3 位和后 4 位，中间用 * 代替 */
    private String maskIdCard(String idCard) {
        if (idCard == null || idCard.length() < 7) {
            return idCard;
        }
        int len = idCard.length();
        StringBuilder sb = new StringBuilder();
        sb.append(idCard, 0, 3);
        sb.append("*".repeat(len - 7));
        sb.append(idCard, len - 4, len);
        return sb.toString();
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
