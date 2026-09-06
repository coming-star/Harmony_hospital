package com.neusoft.hisspringboot.modules.ai.dto;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import com.neusoft.hisspringboot.modules.schedule.dto.SlotSummary;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;
import java.util.List;

/**
 * AI 会话历史消息项。注意：id 为雪花大整数，必须序列化成字符串返回，否则前端 JS 解析会丢精度。
 */
@Schema(description = "AI 会话历史消息项")
public record AiMessageItem(

        @Schema(description = "消息ID", example = "91001")
        @JsonSerialize(using = ToStringSerializer.class)
        Long id,

        @Schema(description = "角色：USER 患者发的 / ASSISTANT AI 回复的", example = "ASSISTANT",
                allowableValues = {"USER", "ASSISTANT"})
        String role,

        @Schema(description = "消息内容")
        String content,

        @Schema(description = "AI 附带的号源卡片（仅 ASSISTANT 消息可能携带；重开会话时用于还原卡片渲染）")
        List<SlotSummary> slots,

        @Schema(description = "消息时间")
        LocalDateTime createdAt
) {
}
