package com.neusoft.hisspringboot.modules.ai.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

@Schema(description = "AI 对话请求")
public record ChatRequest(

        @Schema(description = "会话ID（字符串，防精度丢失）；不传或为空 = 自动新建会话，"
                + "首次对话后前端保存响应里的 conversationId 并在后续请求中回传")
        String conversationId,

        @Schema(description = "本次用户消息内容；历史上下文由服务端按会话自动加载，前端无需再传全量 messages")
        @NotBlank(message = "消息内容不能为空")
        String content
) {
}
