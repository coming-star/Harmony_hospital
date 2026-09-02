package com.neusoft.hisspringboot.modules.level.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.common.ToggleStatusRequest;
import com.neusoft.hisspringboot.modules.level.entity.RegistrationLevel;
import com.neusoft.hisspringboot.modules.level.service.AdminLevelService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

/**
 * 管理端挂号级别接口：普通号/专家号/主任医师号的分页查询、新增、编辑、启用/停用、逻辑删除。
 */
@Tag(name = "挂号级别管理", description = "后台挂号级别新增、编辑、停用、删除")
@RestController
@RequestMapping("/api/admin/levels")
@RequiredArgsConstructor
public class AdminLevelController {

    private final AdminLevelService adminLevelService;

    /**
     * 分页查询挂号级别。
     */
    @Operation(
            summary = "分页查询挂号级别",
            description = "挂号级别（普通号/专家号/主任医师号）列表，含挂号费与默认号源数",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/list")
    public ApiResponse<PageResult<RegistrationLevel>> list(
            @Parameter(description = "页码，从 1 开始，默认 1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页条数，默认 10") @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(adminLevelService.list(page, size));
    }

    /**
     * 新增挂号级别。
     */
    @Operation(
            summary = "新增挂号级别",
            description = "新增挂号级别；feeFen 为挂号费（单位：分），defaultQuota 为每个时段默认号源数",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping
    public ApiResponse<Long> create(@Valid @RequestBody RegistrationLevel level) {
        return ApiResponse.success(adminLevelService.create(level));
    }

    /**
     * 编辑挂号级别。
     */
    @Operation(
            summary = "编辑挂号级别",
            description = "修改挂号级别名称、费用、默认号源数等",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}")
    public ApiResponse<Void> update(
            @Parameter(description = "挂号级别ID", required = true) @PathVariable Long id,
            @RequestBody RegistrationLevel level
    ) {
        adminLevelService.update(id, level);
        return ApiResponse.success();
    }

    /**
     * 启用/停用挂号级别。
     */
    @Operation(
            summary = "启用/停用挂号级别",
            description = "请求体 {\"enabled\": 1} 启用、{\"enabled\": 0} 停用；停用后不可再选择该级别挂号",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}/status")
    public ApiResponse<Void> toggleStatus(
            @Parameter(description = "挂号级别ID", required = true) @PathVariable Long id,
            @Valid @RequestBody ToggleStatusRequest request
    ) {
        adminLevelService.toggleStatus(id, request.enabled());
        return ApiResponse.success();
    }

    /**
     * 逻辑删除挂号级别。
     */
    @Operation(
            summary = "逻辑删除挂号级别",
            description = "逻辑删除挂号级别；已有医生或排班引用时返回业务错误",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(
            @Parameter(description = "挂号级别ID", required = true) @PathVariable Long id
    ) {
        adminLevelService.delete(id);
        return ApiResponse.success();
    }
}
