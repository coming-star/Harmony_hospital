package com.neusoft.hisspringboot.modules.ai.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

@Schema(description = "AI 对话请求")
public record ChatRequest(

        @Schema(description = "多轮对话历史（含最新一条用户消息），按时间升序")
        @NotEmpty(message = "消息内容不能为空")
        List<ChatMessage> messages
) {
}
