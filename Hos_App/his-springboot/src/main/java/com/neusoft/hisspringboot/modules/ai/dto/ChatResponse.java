package com.neusoft.hisspringboot.modules.ai.dto;

import com.neusoft.hisspringboot.modules.schedule.dto.SlotSummary;
import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;

@Schema(description = "AI 对话响应")
public record ChatResponse(

        @Schema(description = "AI 回复内容")
        String reply,

        @Schema(description = "AI 查询到的可预约号源（供前端渲染号源卡片；无号源或未查号源时为空）")
        List<SlotSummary> slots
) {
}
