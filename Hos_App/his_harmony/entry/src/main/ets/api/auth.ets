import { get, post, put } from '../utils/request'
import type {
  AppLoginRequest, AppRegisterRequest, AdminLoginRequest,
  LoginResponse, MeResponse, UpdateMeRequest,
  SmsSendRequest, SmsLoginRequest, SmsResetPasswordRequest
} from '../types'

/** 患者注册 → 成功直接返回登录态 */
export function register(body: AppRegisterRequest): Promise<LoginResponse> {
  return post<LoginResponse>('/api/app/auth/register', body)
}
/** 患者登录 */
export function login(body: AppLoginRequest): Promise<LoginResponse> {
  return post<LoginResponse>('/api/app/auth/login', body)
}
/** 发送短信验证码（本地模拟：验证码打印在后端控制台日志） */
export function sendSmsCode(body: SmsSendRequest): Promise<void> {
  return post<void>('/api/app/auth/sms/send', body)
}
/** 短信验证码登录（未注册自动注册） */
export function smsLogin(body: SmsLoginRequest): Promise<LoginResponse> {
  return post<LoginResponse>('/api/app/auth/sms/login', body)
}
/** 短信验证码找回密码 */
export function resetPasswordBySms(body: SmsResetPasswordRequest): Promise<void> {
  return post<void>('/api/app/auth/sms/reset-password', body)
}
/** 患者登出（把 token 加入 Redis 黑名单）*/
export function logoutPatient(): Promise<void> {
  return post<void>('/api/app/auth/logout')
}
/** 管理员登录（管理端会用到）*/
export function adminLogin(body: AdminLoginRequest): Promise<LoginResponse> {
  return post<LoginResponse>('/api/admin/auth/login', body)
}
/** 管理员登出 */
export function adminLogout(): Promise<void> {
  return post<void>('/api/admin/auth/logout')
}
/** 当前登录用户完整信息（含昵称、头像、手机号）*/
export function getMe(): Promise<MeResponse> {
  return get<MeResponse>('/api/me')
}
/** 修改当前登录用户资料（昵称、头像），返回更新后的完整信息 */
export function updateMe(body: UpdateMeRequest): Promise<MeResponse> {
  return put<MeResponse>('/api/me', body)
}
