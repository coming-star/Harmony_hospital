package com.neusoft.hisspringboot.modules.contact.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.contact.dto.ContactRequest;
import com.neusoft.hisspringboot.modules.contact.entity.PatientContact;
import com.neusoft.hisspringboot.modules.contact.service.ContactService;
import com.neusoft.hisspringboot.security.LoginUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 患者端就诊人管理接口。
 * 一个登录账号可绑定多个就诊人（本人或家人），挂号下单时从中选择就诊人。
 */
@Tag(name = "就诊人管理", description = "患者端：查询我的就诊人列表、新增、修改、删除就诊人")
@RestController
@RequestMapping("/api/contacts")
@RequiredArgsConstructor
public class ContactController {

    private final ContactService contactService;

    /**
     * 我的就诊人列表：返回当前账号绑定的全部就诊人。
     */
    @Operation(
            summary = "我的就诊人列表",
            description = "返回当前登录账号绑定的全部就诊人，挂号下单时从中选择",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping
    public ApiResponse<List<PatientContact>> list(Authentication authentication) {
        return ApiResponse.success(contactService.list(currentUserId(authentication)));
    }

    /**
     * 新增就诊人：为当前账号绑定一个就诊人。
     */
    @Operation(
            summary = "新增就诊人",
            description = "为当前账号绑定一个就诊人（可帮家人挂号）；relation 可选 SELF/PARENT/CHILD/SPOUSE/OTHER，不传默认 SELF",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping
    public ApiResponse<Long> create(
            Authentication authentication,
            @Valid @RequestBody ContactRequest request
    ) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(contactService.create(userId, request));
    }

    /**
     * 修改就诊人：只能修改自己账号下的就诊人。
     */
    @Operation(
            summary = "修改就诊人",
            description = "修改就诊人姓名/手机号/关系；只能修改自己账号下的就诊人，越权访问返回 404",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}")
    public ApiResponse<Void> update(
            Authentication authentication,
            @Parameter(description = "就诊人ID", required = true) @PathVariable Long id,
            @Valid @RequestBody ContactRequest request
    ) {
        contactService.update(currentUserId(authentication), id, request);
        return ApiResponse.success();
    }

    /**
     * 删除就诊人：逻辑删除，存在有效挂号记录时拒绝删除。
     */
    @Operation(
            summary = "删除就诊人",
            description = "逻辑删除；该就诊人有待支付/已支付的挂号记录时返回 422 业务错误",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(
            Authentication authentication,
            @Parameter(description = "就诊人ID", required = true) @PathVariable Long id
    ) {
        contactService.delete(currentUserId(authentication), id);
        return ApiResponse.success();
    }

    private Long currentUserId(Authentication authentication) {
        return ((LoginUser) authentication.getPrincipal()).userId();
    }
}
