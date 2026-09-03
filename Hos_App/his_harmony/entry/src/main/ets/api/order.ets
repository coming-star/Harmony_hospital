import { get, post, put } from '../utils/request.ets'
import type {
  OrderDetail, PageResult, CreateOrderRequest,
  DailyCount, DepartmentCount
} from '../types'

export interface OrderListQuery {
  status?: string              // PENDING_PAYMENT / PAID / COMPLETED / CANCELLED
  page?: number                // 从 1 开始，默认 1
  size?: number                // 默认 10
}

export interface AdminOrderListQuery extends OrderListQuery {
  orderNo?: string
  patientKeyword?: string      // 手机号/昵称/就诊人姓名并集
  doctorName?: string
  visitDate?: string           // yyyy-MM-dd
}

/* ------------------- 患者端 ------------------- */
/** 创建预约订单；需要 SETNX 锁防并发重复抢号 */
export function createOrder(body: CreateOrderRequest): Promise<OrderDetail> {
  return post<OrderDetail>('/api/orders', body, { loading: true })
}
/** 模拟支付（秒级成功）*/
export function payOrder(id: number | string): Promise<OrderDetail> {
  return post<OrderDetail>(`/api/orders/${id}/pay`, undefined, { loading: true })
}
/** 用户取消订单 → 归还号源 */
export function cancelOrder(id: number | string): Promise<OrderDetail> {
  return post<OrderDetail>(`/api/orders/${id}/cancel`, undefined, { loading: true })
}
/** 我的挂号记录（分页）*/
export function listMyOrders(q: OrderListQuery): Promise<PageResult<OrderDetail>> {
  return get<PageResult<OrderDetail>>('/api/orders', q)
}
/** 订单详情 */
export function getOrder(id: number | string): Promise<OrderDetail> {
  return get<OrderDetail>(`/api/orders/${id}`)
}

/* ------------------- 管理端（可选，鸿蒙端本期不直接用） ------------------- */
export function listAdminOrders(q: AdminOrderListQuery): Promise<PageResult<OrderDetail>> {
  return get<PageResult<OrderDetail>>('/api/admin/orders/list', q)
}
/** 管理员取消（cancelReason=ADMIN）*/
export function adminCancelOrder(id: number | string): Promise<OrderDetail> {
  return put<OrderDetail>(`/api/admin/orders/${id}/cancel`)
}
/** 工作台：近 7 天预约量趋势 */
export function ordersDailyTrend(): Promise<DailyCount[]> {
  return get<DailyCount[]>('/api/admin/orders/stats/daily-trend')
}
/** 工作台：科室预约量 TOP5 */
export function ordersDepartmentTop(): Promise<DepartmentCount[]> {
  return get<DepartmentCount[]>('/api/admin/orders/stats/department-top')
}
