package com.neusoft.hisspringboot.modules.order.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

@Schema(description = "挂号下单请求")
public record CreateOrderRequest(

        @Schema(description = "预约的号源ID（查询号源接口返回的 slotId）", example = "601001",
                requiredMode = Schema.RequiredMode.REQUIRED)
        @NotNull(message = "预约时段不能为空")
        Long slotId,

        @Schema(description = "就诊人ID（我的就诊人列表接口返回的 id）", example = "4801",
                requiredMode = Schema.RequiredMode.REQUIRED)
        @NotNull(message = "就诊人不能为空")
        Long contactId,

        @Schema(description = "幂等键，客户端生成的唯一字符串（推荐 UUID）；同一用户同一 key 重复提交只生成一笔订单",
                example = "550e8400-e29b-41d4-a716-446655440000", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(message = "幂等键不能为空")
        String idempotencyKey
) {
}
