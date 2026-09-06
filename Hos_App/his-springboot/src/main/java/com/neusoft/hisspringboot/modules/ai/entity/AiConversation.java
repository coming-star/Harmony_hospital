package com.neusoft.hisspringboot.modules.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * AI 对话会话：一个会话 = 患者和 AI 的一个聊天窗口/话题。
 * deleted 字段配合全局逻辑删除配置：deleteById 实际执行 UPDATE deleted=1，查询自动过滤。
 */
@Data
@TableName("ai_conversation")
public class AiConversation {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long userId;

    /** 会话标题，默认"新对话"；首次对话自动取用户首条内容前 20 字 */
    private String title;

    /** 最后一条消息时间，会话列表按它倒序 */
    private LocalDateTime lastMessageAt;

    private Integer deleted;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
