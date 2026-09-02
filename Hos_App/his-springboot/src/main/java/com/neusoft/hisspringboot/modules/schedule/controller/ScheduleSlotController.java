package com.neusoft.hisspringboot.modules.schedule.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.schedule.dto.SlotSummary;
import com.neusoft.hisspringboot.modules.schedule.service.ScheduleSlotService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

/**
 * 患者端号源查询接口：按科室 + 日期查询可预约的医生时段。
 */
@Tag(name = "排班与号源管理", description = "号源查询与后台排班规则新增、编辑、停用、删除")
@RestController
@RequiredArgsConstructor
public class ScheduleSlotController {

    private final ScheduleSlotService scheduleSlotService;

    /**
     * 查询号源：返回指定科室、指定日期仍有余号的时段列表。
     */
    @Operation(
            summary = "查询号源",
            description = "按二级科室和日期查询可预约号源，仅返回 status=OPEN 且 remainingQuota>0 的医生时段；"
                    + "未来 7 日由前端按日期分别调用；结果带 Redis 缓存",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/api/slots")
    public ApiResponse<List<SlotSummary>> query(
            @Parameter(description = "二级科室ID（必填）", required = true, example = "2101")
            @RequestParam Long departmentId,
            @Parameter(description = "就诊日期，格式 yyyy-MM-dd（必填）", required = true, example = "2026-09-04")
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @Parameter(description = "挂号级别ID（普通号/专家号/主任医师号），不传查全部级别", example = "3001")
            @RequestParam(required = false) Long levelId
    ) {
        return ApiResponse.success(scheduleSlotService.query(departmentId, date, levelId));
    }
}
