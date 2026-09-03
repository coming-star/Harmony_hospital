/**
 * 全局请求封装（块 A 最核心的交付物，所有 API 调用必须走这里，禁止页面直接 import http）。
 *
 * 功能清单：
 *   1. 统一 baseUrl、统一 headers（Content-Type + Authorization Bearer）
 *   2. 登录态 401 自动踢到登录页并清除本地 token
 *   3. 业务错误码 → 中文 toast 映射（跟 docs/08-接口文档-演示版.md §错误码目录完全一致）
 *   4. 统一 loading 开关（可选，默认关闭，传 { loading: true } 打开）
 *   5. 统一导出 get / post / put / del 四个方法，返回 Promise<T>（T 是 data 部分，不是外层 ApiResponse）
 *
 * 依赖：http（系统 @ohos.net.http）、promptAction / router（系统）、UserStore（本项目）
 */
import { http } from '@kit.NetworkKit'
import { promptAction } from '@kit.ArkUI'
import router from '@ohos.router'
import { UserStore } from '../store/UserStore'
import { Route } from './theme'

/** 后端地址：模拟器访问宿主机用 10.0.2.2；真机/局域网改成后端电脑的 LAN IP，如 http://192.168.1.100:8080 */
export const BASE_URL = 'http://10.0.2.2:8080'

/** 业务错误码 → 中文文案（与后端 ErrorCode 枚举一一对应）*/
const BIZ_MSG: Record<number, string> = {
  409001: '该手机号已注册，请直接登录',
  409002: '该身份证已绑定其他就诊人',
  409003: '该时段已约满，请换一个时段',
  409004: '订单状态已变化，操作不可执行',
  409005: '存在关联数据引用，请先停用或取消',
  409006: '编码已存在'
}

export interface RequestOptions {
  loading?: boolean        // 是否显示"加载中"系统 toast，默认 false
  headers?: Record<string, string>
  /** 返回完整 ApiResponse，不剥 data 层；极少数场景（如分页外层 total）使用 */
  raw?: boolean
}

export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

function toast(msg: string, duration = 1500): void {
  try { promptAction.showToast({ message: msg, duration }) } catch (_) { /* ignore */ }
}

function showLoading(on: boolean): void {
  if (!on) return
  try { promptAction.showDialog({ message: '加载中…' }).catch(() => {}) } catch (_) {}
}

function mergeHeaders(custom?: Record<string, string>): Record<string, string> {
  const token = UserStore.getToken()
  const h: Record<string, string> = {
    'Content-Type': 'application/json; charset=UTF-8',
    Accept: 'application/json',
    ...(custom ?? {})
  }
  if (token) h['Authorization'] = `Bearer ${token}`
  return h
}

function handleHttpError(resp: http.HttpResponse): void {
  if (resp.responseCode === 401) {
    UserStore.logoutSync()
    toast('登录已失效，请重新登录')
    try {
      router.replaceUrl({ url: Route.LOGIN })
    } catch (_) {}
    return
  }
  if (resp.responseCode === 403) {
    toast('您没有权限进行此操作')
    return
  }
  if (resp.responseCode === 429) {
    toast('请求过于频繁，请稍后再试')
    return
  }
  if (resp.responseCode >= 500) {
    toast('服务器繁忙，请稍后重试')
    return
  }
}

/** 通用请求内核：统一 ApiResponse 解包 + 错误处理 */
async function request<T>(
  method: http.RequestMethod,
  path: string,
  queryOrBody?: unknown,
  opts: RequestOptions = {}
): Promise<T> {
  const url = path.startsWith('http') ? path : `${BASE_URL}${path}`
  let finalUrl = url

  // GET/DELETE：queryOrBody 拼 query
  if ((method === http.RequestMethod.GET || method === http.RequestMethod.DELETE)
      && queryOrBody && typeof queryOrBody === 'object') {
    const params: string[] = []
    Object.entries(queryOrBody as Record<string, unknown>).forEach(([k, v]) => {
      if (v === null || v === undefined || v === '') return
      params.push(`${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
    })
    if (params.length) finalUrl += (finalUrl.includes('?') ? '&' : '?') + params.join('&')
  }

  showLoading(!!opts.loading)

  let resp: http.HttpResponse
  try {
    const httpRequest = http.createHttp()
    const extraData = (method === http.RequestMethod.POST || method === http.RequestMethod.PUT)
      ? (queryOrBody !== undefined ? JSON.stringify(queryOrBody) : undefined)
      : undefined

    resp = await httpRequest.request(finalUrl, {
      method,
      header: mergeHeaders(opts.headers),
      extraData,
      connectTimeout: 15000,
      readTimeout: 15000
    })
    httpRequest.destroy()
  } catch (e: unknown) {
    toast('网络异常，请检查网络后重试')
    throw e
  }

  // 非 2xx：按 HTTP 状态处理
  if (resp.responseCode < 200 || resp.responseCode >= 300) {
    handleHttpError(resp)
    const err = new Error(`HTTP ${resp.responseCode}`)
    ;(err as Error & { code?: number }).code = resp.responseCode
    throw err
  }

  // 解析 JSON
  let payload: ApiResponse<T>
  try {
    payload = typeof resp.result === 'string'
      ? JSON.parse(resp.result) as ApiResponse<T>
      : (resp.result as ApiResponse<T>)
  } catch (_) {
    toast('响应格式错误')
    throw new Error('Invalid JSON response')
  }

  // 业务 code 不是 200：根据 code 弹 toast
  if (payload.code !== 200) {
    const msg = BIZ_MSG[payload.code] ?? payload.message ?? '操作失败'
    toast(msg)
    const err = new Error(msg)
    ;(err as Error & { code?: number }).code = payload.code
    throw err
  }

  return (opts.raw ? (payload as unknown as T) : payload.data) as T
}

/** 导出的四个方法；调用示例：const list = await get<DepartmentTreeNode[]>('/api/departments/tree') */
export function get<T>(url: string, query?: Record<string, unknown>, opts?: RequestOptions): Promise<T> {
  return request<T>(http.RequestMethod.GET, url, query, opts)
}

export function post<T>(url: string, body?: unknown, opts?: RequestOptions): Promise<T> {
  return request<T>(http.RequestMethod.POST, url, body, opts)
}

export function put<T>(url: string, body?: unknown, opts?: RequestOptions): Promise<T> {
  return request<T>(http.RequestMethod.PUT, url, body, opts)
}

export function del<T>(url: string, query?: Record<string, unknown>, opts?: RequestOptions): Promise<T> {
  return request<T>(http.RequestMethod.DELETE, url, query, opts)
}
