import { get, post } from '../utils/request'
import type {
  AppLoginRequest, AppRegisterRequest, AdminLoginRequest,
  LoginResponse, LoginUser
} from '../types'

/** 患者注册 → 成功直接返回登录态 */
export function register(body: AppRegisterRequest): Promise<LoginResponse> {
  return post<LoginResponse>('/api/app/auth/register', body)
}
/** 患者登录 */
export function login(body: AppLoginRequest): Promise<LoginResponse> {
  return post<LoginResponse>('/api/app/auth/login', body)
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
/** 当前登录用户信息（患者+管理员通用）*/
export function getMe(): Promise<LoginUser> {
  return get<LoginUser>('/api/me')
}
