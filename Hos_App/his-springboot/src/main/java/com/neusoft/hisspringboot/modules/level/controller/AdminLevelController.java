package com.neusoft.hisspringboot.modules.level.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.ToggleStatusRequest;
import com.neusoft.hisspringboot.modules.level.entity.RegistrationLevel;
import com.neusoft.hisspringboot.modules.level.service.AdminLevelService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

@Tag(name = "后台-挂号级别", description = "WEB-07 挂号级别管理")
@RestController
@RequestMapping("/api/admin/levels")
@RequiredArgsConstructor
public class AdminLevelController {

    private final AdminLevelService adminLevelService;

    @Operation(summary = "分页查询挂号级别", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @GetMapping("/list")
    public ApiResponse<PageResult<RegistrationLevel>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(adminLevelService.list(page, size));
    }

    @Operation(summary = "新增挂号级别", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PostMapping
    public ApiResponse<Long> create(@Valid @RequestBody RegistrationLevel level) {
        return ApiResponse.success(adminLevelService.create(level));
    }

    @Operation(summary = "编辑挂号级别", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}")
    public ApiResponse<Void> update(@PathVariable Long id, @RequestBody RegistrationLevel level) {
        adminLevelService.update(id, level);
        return ApiResponse.success();
    }

    @Operation(summary = "启用/停用挂号级别", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}/status")
    public ApiResponse<Void> toggleStatus(@PathVariable Long id, @Valid @RequestBody ToggleStatusRequest request) {
        adminLevelService.toggleStatus(id, request.enabled());
        return ApiResponse.success();
    }

    @Operation(summary = "逻辑删除挂号级别", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        adminLevelService.delete(id);
        return ApiResponse.success();
    }
}
