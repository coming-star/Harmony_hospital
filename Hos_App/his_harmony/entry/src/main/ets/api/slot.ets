import { get } from '../utils/request'
import type { SlotSummary } from '../types'

export interface SlotQuery {
  departmentId: number | string
  date: string            // yyyy-MM-dd
  levelId?: number | string
}

/** 号源查询：按 科室 + 日期 查询，前端遍历未来 7 天分别调用。已缓存。 */
export function listSlots(q: SlotQuery): Promise<SlotSummary[]> {
  return get<SlotSummary[]>('/api/slots', {
    departmentId: q.departmentId,
    date: q.date,
    ...(q.levelId ? { levelId: q.levelId } : {})
  })
}
