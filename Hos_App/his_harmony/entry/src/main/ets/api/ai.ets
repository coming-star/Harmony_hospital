import { get, post } from '../utils/request.ets'

export interface ChatMessageIn {
  /** 用户输入的自然语言文本 */
  prompt: string
}

export interface ChatMessageOut {
  /** AI 回复内容（非流式一次性返回完整答案；流式后续改 SSE/WebSocket）*/
  reply: string
  conversationId?: string
}

export interface ConversationItem {
  id: string
  title: string
  updatedAt: string
}

/** 发送一句话给 AI 导诊（本期：先 mock 非流式）*/
export function aiChat(body: ChatMessageIn): Promise<ChatMessageOut> {
  return post<ChatMessageOut>('/api/ai/chat', body, { loading: true })
}
/** 会话历史列表 */
export function aiConversations(): Promise<ConversationItem[]> {
  return get<ConversationItem[]>('/api/ai/conversations')
}
