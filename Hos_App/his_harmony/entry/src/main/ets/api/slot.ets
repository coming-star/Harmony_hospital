import { get } from '../utils/request'
import type { SlotSummary } from '../types'

export interface SlotQuery {
  departmentId: number | string
  date: string            // yyyy-MM-dd
  levelId?: number | string
}

/** 号源查询：按 科室 + 日期 查询，前端遍历未来 7 天分别调用。已缓存。 */
export function listSlots(q: SlotQuery): Promise<SlotSummary[]> {
  const query: Map<string, string> = new Map<string, string>()
  query.set('departmentId', String(q.departmentId))
  query.set('date', q.date)
  if (q.levelId) {
    query.set('levelId', String(q.levelId))
  }
  return get<SlotSummary[]>('/api/slots', query)
}

/** 号源详情：订单确认页按 slotId 查询单个时段（医生/时间/费用）。 */
export function getSlot(slotId: number | string): Promise<SlotSummary> {
  return get<SlotSummary>(`/api/slots/${slotId}`)
}
