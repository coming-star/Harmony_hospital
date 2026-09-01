package com.neusoft.hisspringboot.modules.schedule.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.ToggleStatusRequest;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleRule;
import com.neusoft.hisspringboot.modules.schedule.service.AdminScheduleRuleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

@Tag(name = "排班与号源管理", description = "号源查询与后台排班规则新增、编辑、停用、删除")
@RestController
@RequestMapping("/api/admin/schedule-rules")
@RequiredArgsConstructor
public class AdminScheduleRuleController {

    private final AdminScheduleRuleService adminScheduleRuleService;

    @Operation(summary = "分页查询排班规则", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @GetMapping("/list")
    public ApiResponse<PageResult<ScheduleRule>> list(
            @RequestParam(required = false) String ruleName,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(adminScheduleRuleService.list(ruleName, page, size));
    }

    @Operation(summary = "新增排班规则", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PostMapping
    public ApiResponse<Long> create(@Valid @RequestBody ScheduleRule rule) {
        return ApiResponse.success(adminScheduleRuleService.create(rule));
    }

    @Operation(summary = "编辑排班规则", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}")
    public ApiResponse<Void> update(@PathVariable Long id, @RequestBody ScheduleRule rule) {
        adminScheduleRuleService.update(id, rule);
        return ApiResponse.success();
    }

    @Operation(summary = "启用/停用排班规则", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}/status")
    public ApiResponse<Void> toggleStatus(@PathVariable Long id, @Valid @RequestBody ToggleStatusRequest request) {
        adminScheduleRuleService.toggleStatus(id, request.enabled());
        return ApiResponse.success();
    }

    @Operation(summary = "逻辑删除排班规则", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        adminScheduleRuleService.delete(id);
        return ApiResponse.success();
    }
}
