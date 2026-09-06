package com.neusoft.hisspringboot.modules.notification.controller;

import com.neusoft.hisspringboot.common.ApiResponse;
import com.neusoft.hisspringboot.common.PageResult;
import com.neusoft.hisspringboot.modules.notification.dto.MessageItem;
import com.neusoft.hisspringboot.modules.notification.service.NotificationService;
import com.neusoft.hisspringboot.security.LoginUser;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/**
 * 患者端消息中心：未读数（红点）、分页列表、单条已读、全部已读。
 */
@Tag(name = "消息中心", description = "站内信：订单通知（预约成功/取消/超时取消）与就诊提醒，未读数、列表、标记已读")
@RestController
@RequestMapping("/api/me/messages")
@RequiredArgsConstructor
public class MessageController {

    private final NotificationService notificationService;

    @Operation(
            summary = "未读消息数",
            description = "当前账号未读站内信数量，App 端用于\"我的\"Tab 图标红点与消息入口角标",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping("/unread-count")
    public ApiResponse<Long> unreadCount(Authentication authentication) {
        return ApiResponse.success(notificationService.unreadCount(currentUserId(authentication)));
    }

    @Operation(
            summary = "消息分页列表",
            description = "当前账号的站内信列表，按时间倒序分页返回",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @GetMapping
    public ApiResponse<PageResult<MessageItem>> list(
            Authentication authentication,
            @Parameter(description = "页码，从 1 开始，默认 1") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页条数，默认 10") @RequestParam(defaultValue = "10") int size
    ) {
        return ApiResponse.success(notificationService.list(currentUserId(authentication), page, size));
    }

    @Operation(
            summary = "标记单条已读",
            description = "把指定消息标记为已读，只能操作自己账号下的消息",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/{id}/read")
    public ApiResponse<Boolean> markRead(
            Authentication authentication,
            @Parameter(description = "消息ID", required = true) @PathVariable Long id
    ) {
        notificationService.markRead(currentUserId(authentication), id);
        return ApiResponse.success(Boolean.TRUE);
    }

    @Operation(
            summary = "全部标记已读",
            description = "把当前账号全部未读消息标记为已读",
            security = {@SecurityRequirement(name = HttpHeaders.AUTHORIZATION)}
    )
    @PutMapping("/read-all")
    public ApiResponse<Boolean> markAllRead(Authentication authentication) {
        notificationService.markAllRead(currentUserId(authentication));
        return ApiResponse.success(Boolean.TRUE);
    }

    private Long currentUserId(Authentication authentication) {
        return ((LoginUser) authentication.getPrincipal()).userId();
    }
}
