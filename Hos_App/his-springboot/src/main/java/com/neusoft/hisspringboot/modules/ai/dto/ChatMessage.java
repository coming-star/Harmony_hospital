package com.neusoft.hisspringboot.modules.ai.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "AI 对话消息")
public record ChatMessage(

        @Schema(description = "角色：user 用户 / assistant AI", example = "user")
        String role,

        @Schema(description = "消息内容", example = "我最近头疼，该挂什么科？")
        String content
) {
}
