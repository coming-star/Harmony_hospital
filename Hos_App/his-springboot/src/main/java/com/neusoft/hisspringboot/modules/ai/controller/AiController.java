package com.neusoft.hisspringboot.modules.ai.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.modules.ai.dto.AiMessageItem;
import com.neusoft.hisspringboot.modules.ai.dto.ChatRequest;
import com.neusoft.hisspringboot.modules.ai.dto.ChatResponse;
import com.neusoft.hisspringboot.modules.ai.dto.ConversationItem;
import com.neusoft.hisspringboot.modules.ai.service.AiService;
import com.neusoft.hisspringboot.security.LoginUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * AI 导诊接口（含多会话管理）。路径 /api/ai/** 未命中 app/admin 前缀，
 * 落在 anyRequest().authenticated()，与契约"未登录 401"一致，无需额外在 SecurityConfig 放行。
 */
@Tag(name = "AI 管家", description = "AI 导诊对话（多会话管理、科室推荐、号源咨询、预约引导）")
@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiController {

    private final AiService aiService;

    @Operation(
            summary = "发送消息（会话内对话）",
            description = "conversationId 不传或为空 = 自动新建会话；响应回传 conversationId，前端保存并在后续请求中回传。"
                    + "历史上下文由服务端按会话自动加载（最近 20 条），前端只需传本次消息内容",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping("/chat")
    public ApiResponse<ChatResponse> chat(
            Authentication authentication,
            @Valid @RequestBody ChatRequest request
    ) {
        Long userId = currentUserId(authentication);
        return ApiResponse.success(aiService.chatInConversation(userId, parseId(request.conversationId()), request.content()));
    }

    @Operation(
            summary = "会话列表",
            description = "当前账号的 AI 会话列表，按最后消息时间倒序",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/conversations")
    public ApiResponse<List<ConversationItem>> conversations(Authentication authentication) {
        return ApiResponse.success(aiService.listConversations(currentUserId(authentication)));
    }

    @Operation(
            summary = "新建会话",
            description = "创建一个标题为\"新对话\"的空会话；也可以不调用本接口，直接 chat 时自动建会话",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PostMapping("/conversations")
    public ApiResponse<ConversationItem> createConversation(Authentication authentication) {
        return ApiResponse.success(aiService.createConversation(currentUserId(authentication)));
    }

    @Operation(
            summary = "删除会话",
            description = "逻辑删除指定会话（只能删除自己账号下的会话）",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @DeleteMapping("/conversations/{id}")
    public ApiResponse<Boolean> deleteConversation(
            Authentication authentication,
            @Parameter(description = "会话ID", required = true) @PathVariable Long id
    ) {
        aiService.deleteConversation(currentUserId(authentication), id);
        return ApiResponse.success(Boolean.TRUE);
    }

    @Operation(
            summary = "会话历史消息",
            description = "按时间升序返回会话内全部消息；ASSISTANT 消息可能附带号源卡片（slots），前端据此还原卡片渲染",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/conversations/{id}/messages")
    public ApiResponse<List<AiMessageItem>> messages(
            Authentication authentication,
            @Parameter(description = "会话ID", required = true) @PathVariable Long id
    ) {
        return ApiResponse.success(aiService.listMessages(currentUserId(authentication), id));
    }

    private Long currentUserId(Authentication authentication) {
        return ((LoginUser) authentication.getPrincipal()).userId();
    }

    /** 前端传雪花大整数一律用字符串，这里宽容解析；空/非法返回 null（视为新建会话） */
    private Long parseId(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return Long.parseLong(raw.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
