import { get, post } from '../utils/request'
import type { SlotSummary } from '../types'

/** 单条对话消息（角色：user 用户 / assistant AI）*/
export interface ChatMessageItem {
  role: 'user' | 'assistant'
  content: string
}

export interface ChatMessageIn {
  /** 多轮对话历史（含最新一条用户消息），按时间升序 */
  messages: ChatMessageItem[]
}

export interface ChatMessageOut {
  /** AI 回复内容（非流式一次性返回）*/
  reply: string
  conversationId?: string
  /** AI 查到的可预约号源（前端据此渲染号源卡片；无则空） */
  slots?: SlotSummary[]
}

export interface ConversationItem {
  id: string
  title: string
  updatedAt: string
}

/** 发送多轮对话给 AI 导诊（返回 AI 回复 + 号源）*/
export function aiChat(body: ChatMessageIn): Promise<ChatMessageOut> {
  return post<ChatMessageOut>('/api/ai/chat', body, { loading: true })
}
/** 会话历史列表（后端本期未持久化，暂不调用）*/
export function aiConversations(): Promise<ConversationItem[]> {
  return get<ConversationItem[]>('/api/ai/conversations')
}
