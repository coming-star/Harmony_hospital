import { get, post, put, del } from '../utils/request'
import type { PatientContact, ContactRequest } from '../types'

/** 我的就诊人列表（按创建时间倒序）*/
export function listContacts(): Promise<PatientContact[]> {
  return get<PatientContact[]>('/api/contacts')
}
/** 新增就诊人 → 返回新建 id { contactId } */
export interface ContactId {
  contactId: number
}

export function createContact(body: ContactRequest): Promise<ContactId> {
  return post<ContactId>('/api/contacts', body)
}
/** 编辑就诊人（仅当前用户自己的就诊人）*/
export function updateContact(id: number | string, body: ContactRequest): Promise<void> {
  return put<void>(`/api/contacts/${id}`, body)
}
/** 删除就诊人；若存在未终态订单会返回 409005 */
export function deleteContact(id: number | string): Promise<void> {
  return del<void>(`/api/contacts/${id}`)
}
