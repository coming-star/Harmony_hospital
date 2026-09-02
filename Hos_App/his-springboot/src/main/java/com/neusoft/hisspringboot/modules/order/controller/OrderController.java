package com.neusoft.hisspringboot.modules.order.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.order.dto.CreateOrderRequest;
import com.neusoft.hisspringboot.modules.order.dto.OrderDetail;
import com.neusoft.hisspringboot.modules.order.service.OrderService;
import com.neusoft.hisspringboot.security.LoginUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/**
 * 患者端挂号接口：预约下单、模拟支付、取消订单、我的挂号记录、订单详情。
 */
@Tag(name = "挂号记录管理", description = "预约下单、支付、取消、查询与后台挂号记录查询、管理员取消")
@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    /**
     * 创建预约订单：校验号源余量并扣减，幂等键防重复提交，Redis 锁防并发抢号。
     */
    @Operation(
            summary = "创建预约订单",
            description = "选择号源和就诊人下单；同一 (用户, idempotencyKey) 重复提交返回同一笔订单；"
                    + "号源被抢完返回 409003；并发请求由 Redis 分布式锁拦截",
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

    /**
     * 模拟支付：待支付订单支付成功，重复调用幂等。
     */
    @Operation(
            summary = "模拟支付",
            description = "仅 PENDING_PAYMENT（待支付）可支付成功；已支付重复调用幂等返回，已取消/已完成返回 409004",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping("/{id}/pay")
    public ApiResponse<OrderDetail> pay(
            Authentication authentication,
            @Parameter(description = "订单ID", required = true) @PathVariable Long id
    ) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(orderService.pay(userId, id));
    }

    /**
     * 取消订单：待支付订单可取消，号源余量自动归还。
     */
    @Operation(
            summary = "取消订单",
            description = "仅 PENDING_PAYMENT（待支付）可取消并归还号源；已取消重复调用幂等返回，其他状态返回 409004",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping("/{id}/cancel")
    public ApiResponse<OrderDetail> cancel(
            Authentication authentication,
            @Parameter(description = "订单ID", required = true) @PathVariable Long id
    ) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(orderService.cancelByUser(userId, id));
    }

    /**
     * 我的挂号记录：分页查询当前账号的订单，可按状态筛选。
     */
    @Operation(
            summary = "我的挂号记录",
            description = "分页查询当前登录账号的挂号订单，可按订单状态筛选",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping
    public ApiResponse<PageResult<OrderDetail>> list(
            Authentication authentication,
            @Parameter(description = "订单状态：PENDING_PAYMENT待支付/PAID已支付/COMPLETED已完成/CANCELLED已取消，不传查全部")
            @RequestParam(required = false) String status,
            @Parameter(description = "页码，从 1 开始，默认 1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页条数，默认 10") @RequestParam(defaultValue = "10") int size
    ) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(orderService.list(userId, status, page, size));
    }

    /**
     * 订单详情：查询单笔订单的完整信息。
     */
    @Operation(
            summary = "订单详情",
            description = "查询单笔挂号订单详情，只能查看自己账号下的订单",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/{id}")
    public ApiResponse<OrderDetail> detail(
            Authentication authentication,
            @Parameter(description = "订单ID", required = true) @PathVariable Long id
    ) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(orderService.detail(userId, id));
    }

    private Long currentUserId(Authentication authentication) {
        return ((LoginUser) authentication.getPrincipal()).userId();
    }
}
