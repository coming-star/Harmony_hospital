package com.neusoft.hisspringboot.modules.order.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateOrderRequest(

        @NotNull(message = "预约时段不能为空")
        Long slotId,

        @NotNull(message = "就诊人不能为空")
        Long contactId,

        @NotBlank(message = "幂等键不能为空")
        String idempotencyKey
) {
}
