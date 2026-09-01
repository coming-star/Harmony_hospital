package com.neusoft.hisspringboot.modules.user.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neusoft.hisspringboot.common.BusinessException;
import com.neusoft.hisspringboot.common.ErrorCode;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.user.dto.AdminUserRequest;
import com.neusoft.hisspringboot.modules.user.dto.AdminUserResponse;
import com.neusoft.hisspringboot.modules.user.entity.SysUser;
import com.neusoft.hisspringboot.modules.user.mapper.SysUserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * 后台"用户管理"（WEB-03）：仅管理 PATIENT 账号，管理员账号不在此列表中维护。
 */
@Service
@RequiredArgsConstructor
public class AdminUserService {

    private static final String USER_TYPE_PATIENT = "PATIENT";

    private final SysUserMapper sysUserMapper;
    private final PasswordEncoder passwordEncoder;

    public PageResult<AdminUserResponse> list(String phone, Integer status, int page, int size) {
        Page<SysUser> mpPage = sysUserMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getUserType, USER_TYPE_PATIENT)
                        .like(phone != null && !phone.isBlank(), SysUser::getPhone, phone)
                        .eq(status != null, SysUser::getStatus, status)
                        .orderByDesc(SysUser::getCreatedAt)
        );

        return PageResult.of(
                mpPage.getRecords().stream().map(this::toResponse).toList(),
                mpPage.getTotal(),
                page,
                size
        );
    }

    @Transactional
    public Long create(AdminUserRequest request) {
        ensurePhoneAvailable(request.phone(), null);

        if (request.password() == null || request.password().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "新增用户必须设置初始密码");
        }

        SysUser user = new SysUser();
        user.setPhone(request.phone());
        user.setNickname(request.nickname());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setUserType(USER_TYPE_PATIENT);
        user.setStatus(1);
        sysUserMapper.insert(user);

        return user.getId();
    }

    @Transactional
    public void update(Long id, AdminUserRequest request) {
        SysUser user = getOrThrow(id);
        ensurePhoneAvailable(request.phone(), id);

        user.setPhone(request.phone());
        user.setNickname(request.nickname());

        if (request.password() != null && !request.password().isBlank()) {
            user.setPasswordHash(passwordEncoder.encode(request.password()));
        }

        sysUserMapper.updateById(user);
    }

    public void toggleStatus(Long id, Integer enabled) {
        SysUser user = getOrThrow(id);
        user.setStatus(enabled);
        sysUserMapper.updateById(user);
    }

    public void delete(Long id) {
        getOrThrow(id);
        sysUserMapper.deleteById(id);
    }

    private void ensurePhoneAvailable(String phone, Long excludeId) {
        Long count = sysUserMapper.selectCount(
                new LambdaQueryWrapper<SysUser>()
                        .eq(SysUser::getPhone, phone)
                        .ne(excludeId != null, SysUser::getId, excludeId)
        );

        if (count > 0) {
            throw new BusinessException(ErrorCode.PHONE_ALREADY_REGISTERED);
        }
    }

    private SysUser getOrThrow(Long id) {
        SysUser user = sysUserMapper.selectById(id);

        if (user == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "用户不存在");
        }

        return user;
    }

    private AdminUserResponse toResponse(SysUser user) {
        return new AdminUserResponse(
                user.getId(),
                user.getPhone(),
                user.getNickname(),
                user.getUserType(),
                user.getStatus(),
                user.getCreatedAt(),
                user.getLastLoginAt()
        );
    }
}
