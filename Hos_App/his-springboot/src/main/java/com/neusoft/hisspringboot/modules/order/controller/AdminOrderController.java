package com.neusoft.hisspringboot.modules.order.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.order.dto.OrderDetail;
import com.neusoft.hisspringboot.modules.order.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@Tag(name = "后台-挂号记录", description = "WEB-08 挂号记录查询与管理员取消")
@RestController
@RequestMapping("/api/admin/orders")
@RequiredArgsConstructor
public class AdminOrderController {

    private final OrderService orderService;

    @Operation(summary = "分页查询挂号记录", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @GetMapping("/list")
    public ApiResponse<PageResult<OrderDetail>> list(
            @RequestParam(required = false) String orderNo,
            @RequestParam(required = false) String patientKeyword,
            @RequestParam(required = false) String doctorName,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate visitDate,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(
                orderService.adminList(orderNo, patientKeyword, doctorName, visitDate, status, page, size)
        );
    }

    @Operation(summary = "管理员取消订单", security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)})
    @PutMapping("/{id}/cancel")
    public ApiResponse<OrderDetail> cancel(@PathVariable Long id) {
        return ApiResponse.success(orderService.cancelByAdmin(id));
    }
}
