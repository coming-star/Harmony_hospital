package com.neusoft.hisspringboot.modules.order.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.order.dto.CreateOrderRequest;
import com.neusoft.hisspringboot.modules.order.dto.OrderDetail;
import com.neusoft.hisspringboot.modules.order.service.OrderService;
import com.neusoft.hisspringboot.security.LoginUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Tag(name = "挂号订单", description = "预约下单、模拟支付、取消与查询")
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @Operation(
            summary = "创建预约订单",
            description = "同一 (用户, idempotencyKey) 重复提交返回同一笔订单；号源被抢完返回 409003",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping
    public ApiResponse<OrderDetail> create(
            Authentication authentication,
            @Valid @RequestBody CreateOrderRequest request
    ) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(orderService.createOrder(userId, request));
    }

    @Operation(
            summary = "模拟支付",
            description = "仅 PENDING_PAYMENT 可支付成功；已支付重复调用幂等返回，已取消/已完成返回 409004",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping("/{id}/pay")
    public ApiResponse<OrderDetail> pay(Authentication authentication, @PathVariable Long id) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(orderService.pay(userId, id));
    }

    @Operation(
            summary = "取消订单",
            description = "仅 PENDING_PAYMENT 可取消并归还号源；已取消重复调用幂等返回，其他状态返回 409004",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping("/{id}/cancel")
    public ApiResponse<OrderDetail> cancel(Authentication authentication, @PathVariable Long id) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(orderService.cancelByUser(userId, id));
    }

    @Operation(
            summary = "我的挂号记录",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping
    public ApiResponse<PageResult<OrderDetail>> list(
            Authentication authentication,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(orderService.list(userId, status, page, size));
    }

    @Operation(
            summary = "订单详情",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/{id}")
    public ApiResponse<OrderDetail> detail(Authentication authentication, @PathVariable Long id) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(orderService.detail(userId, id));
    }

    private Long currentUserId(Authentication authentication) {
        return ((LoginUser) authentication.getPrincipal()).userId();
    }
}
