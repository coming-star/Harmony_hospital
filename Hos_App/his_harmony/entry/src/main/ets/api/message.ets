/**
 * 消息中心（站内信）API：未读数、分页列表、单条已读、全部已读。
 * 未读数会写入 AppStorage 的 'unreadMsgCount'，供 Index"我的"Tab 红点与
 * MineTab 消息入口角标读取（@StorageProp 观察）。
 */
import { get, put } from '../utils/request'
import userStore from '../store/UserStore'
import type { MessageItem, PageResult } from '../types'

/** 当前账号未读消息数 */
export function getUnreadCount(): Promise<number> {
  return get<number>('/api/me/messages/unread-count')
}

/** 消息分页列表（时间倒序） */
export function listMessages(page: number, size: number): Promise<PageResult<MessageItem>> {
  const query: Map<string, string> = new Map<string, string>()
  query.set('page', String(page))
  query.set('size', String(size))
  return get<PageResult<MessageItem>>('/api/me/messages', query)
}

/** 标记单条已读 */
export function markMessageRead(id: string): Promise<boolean> {
  return put<boolean>(`/api/me/messages/${id}/read`)
}

/** 全部标记已读 */
export function markAllMessagesRead(): Promise<boolean> {
  return put<boolean>('/api/me/messages/read-all')
}

/**
 * 刷新全局未读数红点：登录后调用（进 App、切 Tab、消息页操作后）。
 * 未登录时清零；请求失败静默忽略，不打扰用户。
 */
export async function refreshUnreadBadge(): Promise<void> {
  if (!userStore.isLoggedIn()) {
    AppStorage.setOrCreate('unreadMsgCount', 0)
    return
  }
  try {
    const count: number = await getUnreadCount()
    AppStorage.setOrCreate('unreadMsgCount', count)
  } catch (_) { /* 网络失败不打扰用户 */ }
}
