/**
 * 全局主题设计令牌（ArkTS 侧直接用的常量）。
 * 页面与组件里禁止直接写 #色值 / 16vp 这种字面量，一律从这里引用。
 * 颜色优先用 $r('app.color.xxx')（由 color.json 管理），
 * 间距/字号/圆角优先用 $r('app.float.xxx')（由 float.json 管理），
 * 这里主要放代码侧需要的"命名+组合"，比如线性渐变颜色对、阴影 BlurStyle 等。
 */
export class Theme {
  // ========== 色（对应 color.json，方便代码侧做条件判断）==========
  // 统一品牌蓝 (#0A66C2)，与登录/注册/首页参考图完全一致
  static readonly PRIMARY = '#0A66C2'
  static readonly PRIMARY_LIGHT = '#E8F1FC'
  static readonly SECONDARY_BOOKING = '#0A66C2'
  static readonly SECONDARY_AI = '#0A66C2'
  static readonly SUCCESS = '#16A34A'
  static readonly WARNING = '#F59E0B'
  static readonly DANGER = '#DB3A2F'
  static readonly TEXT_PRIMARY = '#1A1A1A'
  static readonly TEXT_SECONDARY = '#5B6370'
  static readonly TEXT_HINT = '#9CA3AF'
  static readonly INPUT_BG = '#F5F7FA'
  static readonly BG_PAGE = '#FAFBFC'
  static readonly BG_CARD = '#FFFFFF'
  static readonly DIVIDER = '#EAECF0'

  // Tabs 图标 & 标签选中色：全部统一主品牌蓝（和参考图 Tabs 一样：选中全蓝）
  static TabActiveColor: Record<string, string> = {
    home: Theme.PRIMARY,
    appointment: Theme.PRIMARY,
    ai: Theme.PRIMARY,
    mine: Theme.PRIMARY
  }

  // ========== 通用圆角/阴影组合方法 ==========
  static cardStyle(): void {} // 占位：实际用法见 FeeTag / SectionTitle 组件
}

/**
 * 全局枚举：路由名（main_pages.json 中注册的路径，带 pages/ 前缀）。
 * 页面跳转统一走这里，别在各页面写死字符串，避免拼写错误。
 */
export class Route {
  static readonly HOME          = 'pages/Index'
  static readonly LOGIN         = 'pages/auth/Login'
  static readonly REGISTER      = 'pages/auth/Register'
  static readonly APPOINTMENT   = 'pages/appointment/AppointmentIndex'
  static readonly DEPT_SELECT   = 'pages/appointment/DepartmentSelect'
  static readonly DOCTOR_LIST   = 'pages/appointment/DoctorList'
  static readonly CONTACT_SELECT= 'pages/appointment/ContactSelect'
  static readonly ORDER_CONFIRM = 'pages/appointment/OrderConfirm'
  static readonly BOOK_SUCCESS  = 'pages/appointment/BookingSuccess'
  static readonly AI_CHAT       = 'pages/ai/AIChat'
  static readonly MINE          = 'pages/mine/MineIndex'
  static readonly ORDER_RECORD  = 'pages/mine/OrderRecord'
  static readonly CONTACT_MGNT  = 'pages/mine/ContactManage'
  static readonly SETTINGS      = 'pages/mine/Settings'
}

/**
 * Tabs 四个底部 Tab 的 key，用于 Index 的 Tabs 组件 selectedIndex。
 */
export const TAB_KEYS = ['home', 'appointment', 'ai', 'mine'] as const
export type TabKey = (typeof TAB_KEYS)[number]
export const TAB_LABELS: Record<TabKey, string> = {
  home: '首页',
  appointment: '预约',
  ai: 'AI',
  mine: '我的'
}
export const TAB_INDEX: Record<TabKey, number> = {
  home: 0,
  appointment: 1,
  ai: 2,
  mine: 3
}
