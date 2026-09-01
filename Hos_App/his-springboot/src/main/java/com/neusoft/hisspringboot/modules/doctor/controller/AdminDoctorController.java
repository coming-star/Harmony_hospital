package com.neusoft.hisspringboot.modules.doctor.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.ToggleStatusRequest;
import com.neusoft.hisspringboot.modules.doctor.dto.AdminDoctorRequest;
import com.neusoft.hisspringboot.modules.doctor.dto.AdminDoctorResponse;
import com.neusoft.hisspringboot.modules.doctor.service.AdminDoctorService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

@Tag(name = "后台-医生管理", description = "WEB-05 医生管理")
@RestController
@RequestMapping("/api/admin/doctors")
@RequiredArgsConstructor
public class AdminDoctorController {

    private final AdminDoctorService adminDoctorService;

    @Operation(summary = "分页查询医生", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @GetMapping("/list")
    public ApiResponse<PageResult<AdminDoctorResponse>> list(
            @RequestParam(required = false) String name,
            @RequestParam(required = false) Long departmentId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(adminDoctorService.list(name, departmentId, page, size));
    }

    @Operation(summary = "新增医生", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PostMapping
    public ApiResponse<Long> create(@Valid @RequestBody AdminDoctorRequest request) {
        return ApiResponse.success(adminDoctorService.create(request));
    }

    @Operation(summary = "编辑医生", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}")
    public ApiResponse<Void> update(@PathVariable Long id, @Valid @RequestBody AdminDoctorRequest request) {
        adminDoctorService.update(id, request);
        return ApiResponse.success();
    }

    @Operation(summary = "启用/停用医生", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}/status")
    public ApiResponse<Void> toggleStatus(@PathVariable Long id, @Valid @RequestBody ToggleStatusRequest request) {
        adminDoctorService.toggleStatus(id, request.enabled());
        return ApiResponse.success();
    }

    @Operation(summary = "逻辑删除医生", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        adminDoctorService.delete(id);
        return ApiResponse.success();
    }
}
