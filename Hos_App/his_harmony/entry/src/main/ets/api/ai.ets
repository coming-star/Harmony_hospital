import { get, post, del } from '../utils/request'
import type { SlotSummary } from '../types'

/**
 * AI 管家 API：会话内对话 + 多会话管理。
 * 雪花大整数 ID（会话/消息）全链路字符串传递，禁止 Number() 转换。
 */

export interface AiChatIn {
  /** 会话 ID（字符串，防精度丢失）；不传或为空 = 服务端自动新建会话 */
  conversationId?: string
  /** 本次用户消息；历史上下文由服务端按会话自动加载 */
  content: string
}

export interface AiChatOut {
  /** 会话 ID：首次对话自动建会话后返回，保存并在后续请求中回传 */
  conversationId?: string
  /** AI 回复内容（非流式一次性返回）*/
  reply: string
  /** AI 查到的可预约号源（前端据此渲染号源卡片；无则空） */
  slots?: SlotSummary[]
}

export interface ConversationItem {
  /** 会话 ID（字符串，防精度丢失） */
  id: string
  title: string
  lastMessageAt?: string
}

export interface AiHistoryMessage {
  /** 消息 ID（字符串，防精度丢失） */
  id: string
  /** USER 患者发的 / ASSISTANT AI 回复的 */
  role: 'USER' | 'ASSISTANT'
  content: string
  /** AI 附带的号源卡片（仅 ASSISTANT 消息可能携带） */
  slots?: SlotSummary[]
  createdAt?: string
}

/** 会话内对话：conversationId 不传 = 自动新建会话 */
export function aiChat(body: AiChatIn): Promise<AiChatOut> {
  return post<AiChatOut>('/api/ai/chat', body, { loading: true })
}

/** 会话列表（按最后消息时间倒序） */
export function listConversations(): Promise<ConversationItem[]> {
  return get<ConversationItem[]>('/api/ai/conversations')
}

/** 新建空会话（也可以不调用，直接 chat 时自动建） */
export function createConversation(): Promise<ConversationItem> {
  return post<ConversationItem>('/api/ai/conversations')
}

/** 删除会话（逻辑删除） */
export function deleteConversation(id: string): Promise<boolean> {
  return del<boolean>(`/api/ai/conversations/${id}`)
}

/** 会话历史消息（升序；ASSISTANT 消息可能附带号源卡片） */
export function conversationMessages(id: string): Promise<AiHistoryMessage[]> {
  return get<AiHistoryMessage[]>(`/api/ai/conversations/${id}/messages`)
}
