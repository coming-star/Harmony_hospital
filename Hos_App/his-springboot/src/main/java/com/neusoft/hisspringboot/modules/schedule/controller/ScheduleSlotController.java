package com.neusoft.hisspringboot.modules.schedule.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.schedule.dto.SlotSummary;
import com.neusoft.hisspringboot.modules.schedule.service.ScheduleSlotService;
import io.swagger.v3.oas.annotations.Operation;
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

@Tag(name = "号源", description = "按科室、日期、号别查询可预约时段")
@RestController
@RequiredArgsConstructor
public class ScheduleSlotController {

    private final ScheduleSlotService scheduleSlotService;

    @Operation(
            summary = "查询号源",
            description = "仅返回 status=OPEN 且 remainingQuota>0 的医生时段，date 为单日查询，"
                    + "未来 7 日由前端按日期分别调用",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/api/slots")
    public ApiResponse<List<SlotSummary>> query(
            @RequestParam Long departmentId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) Long levelId
    ) {
        return ApiResponse.success(scheduleSlotService.query(departmentId, date, levelId));
    }
}
