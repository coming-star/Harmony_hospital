/**
 * 全局请求封装（块 A 最核心的交付物，所有 API 调用必须走这里，禁止页面直接 import http）。
 * ArkTS 严格子集合规版：裸 catch、Map 传参、无索引签名/中括号访问/any/unknown/交叉类型。
 */
import { http } from '@kit.NetworkKit'
import router from '@ohos.router'
import { UserStore } from '../store/UserStore'
import { Route } from './theme'
import { showToast } from './toast'

/** 后端地址：
 *  预览器用 127.0.0.1:8081；真机改成电脑局域网 IP:8081（如 http://192.168.1.100:8081）；
 *  Android 模拟器用 10.0.2.2:8081。后端端口见 application.yml 的 server.port。 */
// export const BASE_URL = 'http://127.0.0.1:8081'
export const BASE_URL = 'http://10.0.2.2:8081'

/** 业务错误码 → 中文文案（与后端 ErrorCode 枚举一一对应）*/
function bizMsg(code: number): string {
  switch (code) {
    case 409001: return '该手机号已注册，请直接登录'
    case 409002: return '该身份证已绑定其他就诊人'
    case 409003: return '该时段已约满，请换一个时段'
    case 409004: return '订单状态已变化，操作不可执行'
    case 409005: return '存在关联数据引用，请先停用或取消'
    case 409006: return '编码已存在'
    default: return ''
  }
}

export interface RequestOptions {
  loading?: boolean
  raw?: boolean
}

export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

function toast(msg: string, duration: number = 1500): void {
  showToast(msg, duration)
}

function showLoading(on: boolean): void {
  if (!on) return
  showToast('加载中…')
}

/** 固定请求头：Content-Type / Accept / Authorization（带 token 才填 Authorization）。
 * 注意：ArkTS 解析器不支持带连字符的引号键名（如 'Content-Type'），
 * 这里用 JSON.parse 从字符串构造请求头对象来绕开。 */
function buildHeaders(): Object {
  const token: string = UserStore.getToken()
  const auth: string = token ? `Bearer ${token}` : ''
  const json: string = `{"Content-Type":"application/json; charset=UTF-8","Accept":"application/json","Authorization":"${auth}"}`
  return JSON.parse(json) as Object
}

function handleHttpError(resp: http.HttpResponse): void {
  if (resp.responseCode === 401) {
    UserStore.instance.logoutSync()
    toast('登录已失效，请重新登录')
    try {
      router.replaceUrl({ url: Route.LOGIN })
    } catch (e) {
    }
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

/** 把 query 的 Map 拼成 URL 查询串 */
function buildQueryString(query: Map<string, string>): string {
  const params: string[] = []
  query.forEach((value: string, key: string) => {
    if (value !== '') {
      params.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
    }
  })
  return params.join('&')
}

async function doRequest<T>(
  method: http.RequestMethod,
  path: string,
  query: Map<string, string>,
  body: Object | undefined,
  opts: RequestOptions
): Promise<T> {
  const url: string = path.startsWith('http') ? path : `${BASE_URL}${path}`
  let finalUrl: string = url

  if ((method === http.RequestMethod.GET || method === http.RequestMethod.DELETE) && query.size > 0) {
    const qs: string = buildQueryString(query)
    if (qs !== '') {
      finalUrl += (finalUrl.includes('?') ? '&' : '?') + qs
    }
  }

  showLoading(!!opts.loading)

  let resp: http.HttpResponse
  try {
    const httpRequest: http.HttpRequest = http.createHttp()
    const extraData: string | undefined = (method === http.RequestMethod.POST || method === http.RequestMethod.PUT)
      ? (body !== undefined ? JSON.stringify(body) : undefined)
      : undefined
    resp = await httpRequest.request(finalUrl, {
      method: method,
      header: buildHeaders(),
      extraData: extraData,
      connectTimeout: 15000,
      readTimeout: 15000
    })
    httpRequest.destroy()
  } catch (e) {
    toast('网络异常，请检查网络后重试')
    throw new Error('网络异常，请检查网络后重试')
  }

  if (resp.responseCode < 200 || resp.responseCode >= 300) {
    handleHttpError(resp)
    throw new Error(`HTTP ${resp.responseCode}`)
  }

  let payload: ApiResponse<T>
  try {
    payload = typeof resp.result === 'string'
      ? JSON.parse(resp.result) as ApiResponse<T>
      : (resp.result as ApiResponse<T>)
  } catch (e) {
    toast('响应格式错误')
    throw new Error('响应格式错误')
  }

  if (payload.code !== 200) {
    const msg: string = bizMsg(payload.code) || payload.message || '操作失败'
    toast(msg)
    throw new Error(msg)
  }

  if (opts.raw) {
    return payload as Object as T
  }
  return payload.data
}

export function get<T>(url: string, query?: Map<string, string>, opts?: RequestOptions): Promise<T> {
  const q: Map<string, string> = query ?? new Map<string, string>()
  return doRequest<T>(http.RequestMethod.GET, url, q, undefined, opts ?? {})
}

export function post<T>(url: string, body?: Object, opts?: RequestOptions): Promise<T> {
  return doRequest<T>(http.RequestMethod.POST, url, new Map<string, string>(), body, opts ?? {})
}

export function put<T>(url: string, body?: Object, opts?: RequestOptions): Promise<T> {
  return doRequest<T>(http.RequestMethod.PUT, url, new Map<string, string>(), body, opts ?? {})
}

export function del<T>(url: string, query?: Map<string, string>, opts?: RequestOptions): Promise<T> {
  const q: Map<string, string> = query ?? new Map<string, string>()
  return doRequest<T>(http.RequestMethod.DELETE, url, q, undefined, opts ?? {})
}
