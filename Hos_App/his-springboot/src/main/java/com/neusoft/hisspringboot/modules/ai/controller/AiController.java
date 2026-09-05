package com.neusoft.hisspringboot.modules.ai.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.ai.dto.ChatRequest;
import com.neusoft.hisspringboot.modules.ai.dto.ChatResponse;
import com.neusoft.hisspringboot.modules.ai.service.AiService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * AI 导诊接口。路径 /api/ai/** 未命中 app/admin 前缀，落在 anyRequest().authenticated()，
 * 与契约"未登录 401"一致，无需额外在 SecurityConfig 放行。
 */
@Tag(name = "AI 管家", description = "AI 导诊对话（科室推荐、号源咨询、预约引导）")
@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiController {

    private final AiService aiService;

    @Operation(
            summary = "发送消息",
            description = "向 AI 导诊助手发送多轮对话，返回 AI 回复；未登录返回 401",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping("/chat")
    public ApiResponse<ChatResponse> chat(@Valid @RequestBody ChatRequest request) {
        return ApiResponse.success(aiService.chat(request.messages()));
    }
}
