package com.neusoft.hisspringboot.modules.notification.dto;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

/**
 * 站内信列表项。注意：id/bizId 为雪花大整数，必须序列化成字符串返回，否则前端 JS 解析会丢精度。
 */
@Schema(description = "站内信消息项")
public record MessageItem(
        @Schema(description = "消息ID", example = "80001")
        @JsonSerialize(using = ToStringSerializer.class)
        Long id,

        @Schema(description = "消息类型：ORDER_PAY_SUCCESS预约成功/ORDER_CANCELLED订单已取消/ORDER_TIMEOUT订单超时取消/VISIT_REMINDER就诊提醒",
                example = "ORDER_PAY_SUCCESS",
                allowableValues = {"ORDER_PAY_SUCCESS", "ORDER_CANCELLED", "ORDER_TIMEOUT", "VISIT_REMINDER"})
        String type,

        @Schema(description = "消息标题", example = "预约成功")
        String title,

        @Schema(description = "消息正文")
        String content,

        @Schema(description = "关联订单ID，可跳订单详情", example = "70001")
        @JsonSerialize(using = ToStringSerializer.class)
        Long bizId,

        @Schema(description = "是否已读：0未读 1已读", example = "0")
        Integer isRead,

        @Schema(description = "消息时间")
        LocalDateTime createdAt
) {
}
