package com.neusoft.hisspringboot.modules.doctor.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.doctor.dto.DoctorDetailResponse;
import com.neusoft.hisspringboot.modules.doctor.service.DoctorService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "医生", description = "医生详情查询")
@RestController
@RequiredArgsConstructor
public class DoctorController {

    private final DoctorService doctorService;

    @Operation(
            summary = "查询医生详情",
            description = "返回医生基础信息、所属科室名称及可提供的挂号级别",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/api/doctors/{id}")
    public ApiResponse<DoctorDetailResponse> detail(@PathVariable Long id) {
        return ApiResponse.success(doctorService.getDetail(id));
    }
}
