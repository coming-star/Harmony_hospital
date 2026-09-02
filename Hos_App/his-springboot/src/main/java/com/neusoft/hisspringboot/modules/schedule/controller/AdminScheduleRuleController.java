package com.neusoft.hisspringboot.modules.schedule.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.ToggleStatusRequest;
import com.neusoft.hisspringboot.modules.schedule.entity.ScheduleRule;
import com.neusoft.hisspringboot.modules.schedule.service.AdminScheduleRuleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

/**
 * 管理端排班规则接口：排班规则是可复用模板，多个医生通过医生-规则关联表引用同一条规则。
 */
@Tag(name = "排班与号源管理", description = "号源查询与后台排班规则新增、编辑、停用、删除")
@RestController
@RequestMapping("/api/admin/schedule-rules")
@RequiredArgsConstructor
public class AdminScheduleRuleController {

    private final AdminScheduleRuleService adminScheduleRuleService;

    /**
     * 分页查询排班规则：可按规则名称模糊搜索。
     */
    @Operation(
            summary = "分页查询排班规则",
            description = "排班规则模板列表，支持按规则名称模糊搜索",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/list")
    public ApiResponse<PageResult<ScheduleRule>> list(
            @Parameter(description = "规则名称（模糊匹配）") @RequestParam(required = false) String ruleName,
            @Parameter(description = "页码，从 1 开始，默认 1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页条数，默认 10") @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(adminScheduleRuleService.list(ruleName, page, size));
    }

    /**
     * 新增排班规则：定义星期掩码、上午/下午和时段 JSON。
     */
    @Operation(
            summary = "新增排班规则",
            description = "新增可复用的排班规则模板；weekdayMask 为 7 位二进制位掩码（bit0-6 对应周一至周日），"
                    + "slotsJson 为时段数组 [{\"start\":\"08:00\",\"end\":\"08:30\",\"quota\":4}]",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping
    public ApiResponse<Long> create(@Valid @RequestBody ScheduleRule rule) {
        return ApiResponse.success(adminScheduleRuleService.create(rule));
    }

    /**
     * 编辑排班规则：修改规则模板，引用该规则的医生排班随之变化。
     */
    @Operation(
            summary = "编辑排班规则",
            description = "修改排班规则模板内容",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}")
    public ApiResponse<Void> update(
            @Parameter(description = "排班规则ID", required = true) @PathVariable Long id,
            @RequestBody ScheduleRule rule
    ) {
        adminScheduleRuleService.update(id, rule);
        return ApiResponse.success();
    }

    /**
     * 启用/停用排班规则。
     */
    @Operation(
            summary = "启用/停用排班规则",
            description = "请求体 {\"enabled\": 1} 启用、{\"enabled\": 0} 停用；停用后不再生成新号源",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}/status")
    public ApiResponse<Void> toggleStatus(
            @Parameter(description = "排班规则ID", required = true) @PathVariable Long id,
            @Valid @RequestBody ToggleStatusRequest request
    ) {
        adminScheduleRuleService.toggleStatus(id, request.enabled());
        return ApiResponse.success();
    }

    /**
     * 逻辑删除排班规则。
     */
    @Operation(
            summary = "逻辑删除排班规则",
            description = "逻辑删除排班规则模板，已生成的历史号源不受影响",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(
            @Parameter(description = "排班规则ID", required = true) @PathVariable Long id
    ) {
        adminScheduleRuleService.delete(id);
        return ApiResponse.success();
    }
}
