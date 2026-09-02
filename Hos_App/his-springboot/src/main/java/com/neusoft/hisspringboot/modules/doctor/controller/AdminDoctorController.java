package com.neusoft.hisspringboot.modules.doctor.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.ToggleStatusRequest;
import com.neusoft.hisspringboot.modules.doctor.dto.AdminDoctorRequest;
import com.neusoft.hisspringboot.modules.doctor.dto.AdminDoctorResponse;
import com.neusoft.hisspringboot.modules.doctor.service.AdminDoctorService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

/**
 * 管理端医生接口：医生分页查询、新增、编辑、启用/停用、逻辑删除。
 * 医生与挂号级别、排班规则均为多对多关系，新增/编辑时传 ID 数组。
 */
@Tag(name = "医生管理", description = "医生详情查询与后台医生新增、编辑、停用、删除")
@RestController
@RequestMapping("/api/admin/doctors")
@RequiredArgsConstructor
public class AdminDoctorController {

    private final AdminDoctorService adminDoctorService;

    /**
     * 分页查询医生：支持姓名、所属二级科室筛选。
     */
    @Operation(
            summary = "分页查询医生",
            description = "医生列表，支持按姓名模糊搜索、按所属二级科室筛选；返回医生的挂号级别和排班规则摘要",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/list")
    public ApiResponse<PageResult<AdminDoctorResponse>> list(
            @Parameter(description = "医生姓名（模糊匹配）") @RequestParam(required = false) String name,
            @Parameter(description = "所属二级科室ID") @RequestParam(required = false) Long departmentId,
            @Parameter(description = "页码，从 1 开始，默认 1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页条数，默认 10") @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(adminDoctorService.list(name, departmentId, page, size));
    }

    /**
     * 新增医生：同时关联挂号级别和排班规则。
     */
    @Operation(
            summary = "新增医生",
            description = "新增医生并绑定所属二级科室；levelIds 为可挂号级别ID数组，scheduleRuleIds 为排班规则模板ID数组（多对多）",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping
    public ApiResponse<Long> create(@Valid @RequestBody AdminDoctorRequest request) {
        return ApiResponse.success(adminDoctorService.create(request));
    }

    /**
     * 编辑医生：可修改基本信息及级别、规则关联。
     */
    @Operation(
            summary = "编辑医生",
            description = "修改医生基本信息；levelIds/scheduleRuleIds 传全量ID数组，后端按数组重建关联",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}")
    public ApiResponse<Void> update(
            @Parameter(description = "医生ID", required = true) @PathVariable Long id,
            @Valid @RequestBody AdminDoctorRequest request
    ) {
        adminDoctorService.update(id, request);
        return ApiResponse.success();
    }

    /**
     * 启用/停用医生：停用后患者端不可见。
     */
    @Operation(
            summary = "启用/停用医生",
            description = "请求体 {\"enabled\": 1} 启用、{\"enabled\": 0} 停用；停用后患者端号源查询不再返回该医生",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}/status")
    public ApiResponse<Void> toggleStatus(
            @Parameter(description = "医生ID", required = true) @PathVariable Long id,
            @Valid @RequestBody ToggleStatusRequest request
    ) {
        adminDoctorService.toggleStatus(id, request.enabled());
        return ApiResponse.success();
    }

    /**
     * 逻辑删除医生。
     */
    @Operation(
            summary = "逻辑删除医生",
            description = "逻辑删除医生；医生名下仍有未来号源或挂号记录时返回业务错误",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(
            @Parameter(description = "医生ID", required = true) @PathVariable Long id
    ) {
        adminDoctorService.delete(id);
        return ApiResponse.success();
    }
}
