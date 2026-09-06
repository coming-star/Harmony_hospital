/**
 * 全局登录态 Store（单例 + Preferences 持久化）。
 * - 登录成功后写 setLogin()：存 token / userId / nickname / userType
 * - 登出后 logout()：清本地并调后端接口把当前 token 加入 Redis 黑名单
 * - 冷启动 / 切换页面：isLoggedIn() 判断、getToken() 给请求头
 *
 * 所有页面不要自己去 Preferences 读写登录态，统一用 UserStore 单例；
 * request.ets 中已经调用 UserStore.getToken() 自动加 Authorization 头。
 */
import { preferences } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import router from '@ohos.router'
import { Route } from '../utils/theme'
import type { LoginResponse, UserType, MeResponse } from '../types'
import * as authApi from '../api/auth'

const STORE_NAME = 'user_store'
const K_TOKEN = 'access_token'
const K_USER_ID = 'user_id'
const K_NICK = 'nickname'
const K_USER_TYPE = 'user_type'
const K_PHONE = 'phone'
const K_AVATAR = 'avatar_url'

export class UserStore {
  private static _i: UserStore | null = null
  static get instance(): UserStore {
    if (!UserStore._i) UserStore._i = new UserStore()
    return UserStore._i
  }

  private prefs?: preferences.Preferences
  private _token: string = ''
  private _userId: number = 0
  private _nickname: string = ''
  private _phone: string = ''
  private _userType: UserType | '' = ''
  private _avatarUrl: string = ''

  /** 是否已完成异步初始化 */
  private inited: boolean = false

  // ---- 初始化（首次用到 any 同步方法时会等待；建议在 EntryAbility.onCreate 调 init() 提前做好）----
  async init(): Promise<void> {
    if (this.inited) return
    try {
      // 注意：Harmony Preferences 的 dataPreferences 需要 Context，
      // 在页面场景可以通过 getContext(this) 拿，这里我们用全局能力拿到的 Context 构造路径。
      // 但 Store 单例没有 Context 时，改用页面 Context 调用 init(context) 版本。
      // 这里提供一个"空 init"保证不抛错，让页面侧在 aboutToAppear 调用 init(ctx)。
      this.inited = true
    } catch (_) { /* ignore */ }
  }

  /** 页面侧初始化（带 Context）*/
  async initWithContext(ctx: Context): Promise<void> {
    if (this.inited && this.prefs) return
    this.prefs = await preferences.getPreferences(ctx, STORE_NAME)
    this._token    = String((await this.prefs.get(K_TOKEN, '')) ?? '')
    const uid: number | string = await this.prefs.get(K_USER_ID, 0) as number | string
    this._userId   = typeof uid === 'number' ? uid : parseInt(String(uid), 10) || 0
    this._nickname = String((await this.prefs.get(K_NICK, '')) ?? '')
    this._phone = String((await this.prefs.get(K_PHONE, '')) ?? '')
    this._userType = (String((await this.prefs.get(K_USER_TYPE, '')) ?? '')) as UserType | ''
    this._avatarUrl = String((await this.prefs.get(K_AVATAR, '')) ?? '')
    this.inited = true
  }

  // ---- 同步 getter（在 UI 里直接显示）----
  get token(): string { return this._token }
  get userId(): number { return this._userId }
  get nickname(): string { return this._nickname }
  get phone(): string { return this._phone }
  get userType(): UserType | '' { return this._userType }
  get avatarUrl(): string { return this._avatarUrl }

  isLoggedIn(): boolean { return !!this._token && this._userId > 0 }
  static getToken(): string { return UserStore.instance.token }

  // ---- 登录 / 登出（会持久化）----
  async setLogin(login: LoginResponse): Promise<void> {
    this._token = login.accessToken
    this._userId = Number(login.userId)
    this._nickname = login.nickname
    this._phone = login.phone ?? ''
    this._userType = login.userType
    if (this.prefs) {
      await this.prefs.put(K_TOKEN, this._token)
      await this.prefs.put(K_USER_ID, this._userId)
      await this.prefs.put(K_NICK, this._nickname)
      await this.prefs.put(K_PHONE, this._phone)
      await this.prefs.put(K_USER_TYPE, this._userType)
      await this.prefs.flush()
    }
    // 登录成功后拉取完整资料（含头像 URL；登录响应里不带头像）
    try {
      const me: MeResponse = await authApi.getMe()
      this.applyMe(me)
    } catch (_) { /* 忽略拉取失败，至少登录信息已落库 */ }
  }

  /** 用 /api/me 返回值更新本地昵称 / 手机号 / 头像（修改资料后调用）*/
  async updateMe(me: MeResponse): Promise<void> {
    this.applyMe(me)
  }

  private applyMe(me: MeResponse): void {
    if (me.nickname !== undefined && me.nickname !== '') this._nickname = me.nickname
    if (me.phone !== undefined) this._phone = me.phone
    this._avatarUrl = me.avatarUrl ?? ''
    if (this.prefs) {
      this.prefs.put(K_NICK, this._nickname)
      this.prefs.put(K_PHONE, this._phone)
      this.prefs.put(K_AVATAR, this._avatarUrl)
      this.prefs.flush()
    }
  }

  /** 登出：先调后端接口把当前 token 加入 Redis 黑名单（成功/失败都清本地）*/
  async logout(): Promise<void> {
    try {
      if (this._userType === 'ADMIN') await authApi.adminLogout()
      else if (this._token)     await authApi.logoutPatient()
    } catch (_) { /* 忽略网络错误 */ }
    this.logoutSync()
  }

  /** 同步清本地（用于 401 自动踢登录等无需等网络返回场景）*/
  logoutSync(): void {
    this._token = ''
    this._userId = 0
    this._nickname = ''
    this._phone = ''
    this._userType = ''
    this._avatarUrl = ''
    if (this.prefs) {
      this.prefs.delete(K_TOKEN)
      this.prefs.delete(K_USER_ID)
      this.prefs.delete(K_NICK)
      this.prefs.delete(K_PHONE)
      this.prefs.delete(K_USER_TYPE)
      this.prefs.delete(K_AVATAR)
      this.prefs.flushSync?.()
    }
    try {
      router.replaceUrl({ url: Route.LOGIN })
    } catch (_) { /* ignore */ }
  }
}

// 导出默认 getter，页面里写：
//   import userStore from '../store/UserStore.ets'
//   Text(userStore.nickname || '未登录')
export default UserStore.instance
