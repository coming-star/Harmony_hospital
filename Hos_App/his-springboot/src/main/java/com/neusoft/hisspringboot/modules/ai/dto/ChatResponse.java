package com.neusoft.hisspringboot.modules.ai.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "AI 对话响应")
public record ChatResponse(

        @Schema(description = "AI 回复内容")
        String reply
) {
}
