package com.neusoft.hisspringboot.modules.order.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.order.dto.DailyCount;
import com.neusoft.hisspringboot.modules.order.dto.DepartmentCount;
import com.neusoft.hisspringboot.modules.order.dto.OrderDetail;
import com.neusoft.hisspringboot.modules.order.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * 管理端挂号记录接口：挂号记录分页查询、管理员取消订单、预约量统计。
 */
@Tag(name = "挂号记录管理", description = "预约下单、支付、取消、查询与后台挂号记录查询、管理员取消")
@RestController
@RequestMapping("/api/admin/orders")
@RequiredArgsConstructor
public class AdminOrderController {

    private final OrderService orderService;

    /**
     * 分页查询挂号记录：支持订单号、就诊人、医生、就诊日期、状态组合筛选。
     */
    @Operation(
            summary = "分页查询挂号记录",
            description = "管理端挂号记录列表，支持订单号、就诊人姓名/手机号、医生姓名、就诊日期、订单状态组合筛选",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/list")
    public ApiResponse<PageResult<OrderDetail>> list(
            @Parameter(description = "订单号（模糊匹配）") @RequestParam(required = false) String orderNo,
            @Parameter(description = "就诊人姓名或手机号（模糊匹配）") @RequestParam(required = false) String patientKeyword,
            @Parameter(description = "医生姓名（模糊匹配）") @RequestParam(required = false) String doctorName,
            @Parameter(description = "就诊日期，格式 yyyy-MM-dd")
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate visitDate,
            @Parameter(description = "订单状态：PENDING_PAYMENT待支付/PAID已支付/COMPLETED已完成/CANCELLED已取消，不传查全部")
            @RequestParam(required = false) String status,
            @Parameter(description = "页码，从 1 开始，默认 1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页条数，默认 10") @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(
                orderService.adminList(orderNo, patientKeyword, doctorName, visitDate, status, page, size)
        );
    }

    /**
     * 管理员取消订单：取消后归还号源余量。
     */
    @Operation(
            summary = "管理员取消订单",
            description = "管理员后台取消挂号订单，取消后号源余量自动归还",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}/cancel")
    public ApiResponse<OrderDetail> cancel(
            @Parameter(description = "订单ID", required = true) @PathVariable Long id
    ) {
        return ApiResponse.success(orderService.cancelByAdmin(id));
    }

    /**
     * 近 7 天预约量趋势：供后台首页折线图使用。
     */
    @Operation(
            summary = "近7天预约量趋势",
            description = "返回最近 7 天每天的预约订单量，供后台首页趋势图使用",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/stats/daily-trend")
    public ApiResponse<List<DailyCount>> dailyTrend() {
        return ApiResponse.success(orderService.dailyTrend());
    }

    /**
     * 科室预约量 TOP5：供后台首页柱状图使用。
     */
    @Operation(
            summary = "科室预约量TOP5",
            description = "返回预约量排名前 5 的科室及订单数，供后台首页统计图使用",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/stats/department-top")
    public ApiResponse<List<DepartmentCount>> departmentTop() {
        return ApiResponse.success(orderService.departmentTop5());
    }
}
