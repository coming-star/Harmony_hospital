package com.neusoft.hisspringboot.modules.ai.dto;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;

/**
 * AI 会话列表项。注意：id 为雪花大整数，必须序列化成字符串返回，否则前端 JS 解析会丢精度。
 */
@Schema(description = "AI 会话列表项")
public record ConversationItem(

        @Schema(description = "会话ID", example = "90001")
        @JsonSerialize(using = ToStringSerializer.class)
        Long id,

        @Schema(description = "会话标题（默认“新对话”，首次对话自动取首条内容前 20 字）", example = "头疼该挂什么科")
        String title,

        @Schema(description = "最后一条消息时间，列表按它倒序")
        LocalDateTime lastMessageAt
) {
}
