package com.neusoft.hisspringboot.modules.ai.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * AI 对话消息：会话里的一问一答各是一行。
 * role：USER 患者发的 / ASSISTANT AI 回复的（SYSTEM/TOOL 本期不落库）。
 * extraJson：ASSISTANT 消息附带的号源卡片列表（SlotSummary JSON 数组），重开会话时还原卡片。
 */
@Data
@TableName("ai_message")
public class AiMessage {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    private Long conversationId;

    private String role;

    private String content;

    /** 扩展数据 JSON（号源卡片），仅 ASSISTANT 消息可能携带 */
    private String extraJson;

    private LocalDateTime createdAt;
}
