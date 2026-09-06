/**
 * 全局类型定义（所有 DTO / 枚举 / 通用包装）。
 * 字段名、注释、示例值与后端 Java DTO / 实体严格对齐，**前端不重复定义 interface**。
 * 任何接口新增字段时，先在这里补 interface，再改调用方页面 / api 模块。
 */

// ============== 通用包装 ==============
export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

export interface PageResult<T> {
  records: T[]
  total: number
  page: number
  size: number
}

export interface ToggleStatusRequest {
  enabled: 0 | 1
}

// ============== 枚举常量（字符串常量，不要页面里写死字面量）==============
export type OrderStatus = 'PENDING_PAYMENT' | 'PAID' | 'COMPLETED' | 'CANCELLED'

export interface OrderStatusMap {
  PENDING_PAYMENT: OrderStatus
  PAID: OrderStatus
  COMPLETED: OrderStatus
  CANCELLED: OrderStatus
}
export const OrderStatusValue: OrderStatusMap = {
  PENDING_PAYMENT: 'PENDING_PAYMENT',
  PAID: 'PAID',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED'
}

export interface OrderStatusTextMap {
  PENDING_PAYMENT: string
  PAID: string
  COMPLETED: string
  CANCELLED: string
}
export const OrderStatusText: OrderStatusTextMap = {
  PENDING_PAYMENT: '待支付',
  PAID: '已支付',
  COMPLETED: '已完成',
  CANCELLED: '已取消'
}

export type Relation = 'SELF' | 'PARENT' | 'CHILD' | 'SPOUSE' | 'OTHER'

export interface RelationMap {
  SELF: Relation
  PARENT: Relation
  CHILD: Relation
  SPOUSE: Relation
  OTHER: Relation
}
export const RelationValue: RelationMap = {
  SELF: 'SELF',
  PARENT: 'PARENT',
  CHILD: 'CHILD',
  SPOUSE: 'SPOUSE',
  OTHER: 'OTHER'
}

export interface RelationTextMap {
  SELF: string
  PARENT: string
  CHILD: string
  SPOUSE: string
  OTHER: string
}
export const RelationText: RelationTextMap = {
  SELF: '本人',
  PARENT: '父母',
  CHILD: '子女',
  SPOUSE: '配偶',
  OTHER: '其他'
}

export interface RelationOption {
  key: Relation
  label: string
}
export const RelationList: RelationOption[] = [
  { key: RelationValue.SELF,   label: RelationText.SELF },
  { key: RelationValue.PARENT, label: RelationText.PARENT },
  { key: RelationValue.CHILD,  label: RelationText.CHILD },
  { key: RelationValue.SPOUSE, label: RelationText.SPOUSE },
  { key: RelationValue.OTHER,  label: RelationText.OTHER }
]

/** 关系枚举 → 中文文案（替代中括号取值 RelationText[r]）*/
export function relationText(r: Relation): string {
  switch (r) {
    case 'SELF': return '本人'
    case 'PARENT': return '父母'
    case 'CHILD': return '子女'
    case 'SPOUSE': return '配偶'
    case 'OTHER': return '其他'
    default: return ''
  }
}

export type Period = 'MORNING' | 'AFTERNOON' | 'EVENING'

export interface PeriodMap {
  MORNING: Period
  AFTERNOON: Period
  EVENING: Period
}
export const PeriodValue: PeriodMap = {
  MORNING: 'MORNING',
  AFTERNOON: 'AFTERNOON',
  EVENING: 'EVENING'
}

export interface PeriodTextMap {
  MORNING: string
  AFTERNOON: string
  EVENING: string
}
export const PeriodText: PeriodTextMap = {
  MORNING: '上午',
  AFTERNOON: '下午',
  EVENING: '晚间'
}

export type UserType = 'PATIENT' | 'ADMIN'

export interface UserTypeMap {
  PATIENT: UserType
  ADMIN: UserType
}
export const UserTypeValue: UserTypeMap = {
  PATIENT: 'PATIENT',
  ADMIN: 'ADMIN'
}

// ============== 认证 ==============
export interface LoginResponse {
  accessToken: string
  tokenType: 'Bearer'
  userId: number
  nickname: string
  phone: string
  userType: UserType
}

export interface LoginUser {
  userId: number
  userType: UserType
  jti: string
}

/** /api/me 返回的当前登录用户完整信息（含昵称、头像、手机号） */
export interface MeResponse {
  /** 雪花大整数 ID，后端以字符串返回 */
  userId: string | number
  userType: UserType
  nickname?: string
  /** 头像 URL，未设置为空 */
  avatarUrl?: string
  phone?: string
}

/** PUT /api/me 修改个人资料请求（两个字段均可选，传哪个改哪个） */
export interface UpdateMeRequest {
  nickname?: string
  avatarUrl?: string
}

export interface AppRegisterRequest {
  phone: string
  password: string
  nickname: string
}

export interface AppLoginRequest {
  phone: string
  password: string
}

export interface AdminLoginRequest {
  username: string
  password: string
}

// ============== 短信验证码登录 / 找回密码 ==============
export type SmsScene = 'LOGIN' | 'RESET_PASSWORD'

export interface SmsSendRequest {
  phone: string
  scene: SmsScene
}

export interface SmsLoginRequest {
  phone: string
  code: string
}

export interface SmsResetPasswordRequest {
  phone: string
  code: string
  newPassword: string
}

// ============== 科室 / 医生 / 号源 ==============
export interface DepartmentTreeNode {
  id: number
  code: string
  name: string
  description: string
  sortNo: number
  children: DepartmentTreeNode[]
}

export interface DoctorLevelBrief {
  levelId: number
  code: string
  name: string
  feeFen: number
}

export interface DoctorDetailResponse {
  id: number
  name: string
  departmentId: number
  departmentName: string
  title: string
  introduction: string
  levels: DoctorLevelBrief[]
}

export interface SlotSummary {
  /** 雪花大整数 ID，后端以字符串返回，前端必须全程按 string 传递（禁止 Number() 转换） */
  slotId: string
  doctorId: number
  doctorName: string
  departmentId: number
  levelId: number
  levelName: string
  /** 挂号费用，单位：分 */
  feeFen: number
  /** yyyy-MM-dd */
  visitDate: string
  /** HH:mm:ss */
  startTime: string
  /** HH:mm:ss */
  endTime: string
  remainingQuota: number
}

// ============== 就诊人 ==============
export interface PatientContact {
  /** 雪花大整数 ID，后端以字符串返回，前端必须全程按 string 传递（禁止 Number() 转换） */
  id: string
  userId: number
  name: string
  phone: string
  relation: Relation
  /** 身份证脱敏值（如 110***********1234），未采集为空 */
  idCardMasked?: string
  /** yyyy-MM-dd HH:mm:ss（部分后端版本可能是 ISO 格式）*/
  createdAt: string
  updatedAt?: string
}

export interface ContactRequest {
  name: string
  phone: string
  /** 不传默认 SELF */
  relation?: Relation
  /** 身份证号（18 位，末位可为 X），可选；后端加密存储且同账号下不允许重复 */
  idCard?: string
}

// ============== 订单 ==============
export interface CreateOrderRequest {
  /** 号源 ID：号源查询返回的 slotId（字符串，防精度丢失） */
  slotId: string
  /** 就诊人 ID：就诊人列表返回的 id（字符串，防精度丢失） */
  contactId: string
  /** 幂等键：客户端生成 UUID（调用 Format.uuid()）*/
  idempotencyKey: string
}

export interface OrderDetail {
  /** 订单 ID（字符串，防精度丢失） */
  id: string
  orderNo: string
  status: OrderStatus
  slotId: string
  doctorId: number
  doctorName: string
  departmentId: number
  departmentName: string
  levelId: number
  levelName: string
  visitDate: string
  startTime: string
  endTime: string
  /** 单位分 */
  amountFen: number
  contactName: string
  contactPhone: string
  expiredAt?: string
  paidAt?: string
  cancelledAt?: string
  cancelReason?: 'USER' | 'ADMIN' | string
  createdAt: string
}

export interface DailyCount {
  date: string
  count: number
}

export interface DepartmentCount {
  name: string
  count: number
}

// ============== 消息中心 ==============
export type MessageType = 'ORDER_PAY_SUCCESS' | 'ORDER_CANCELLED' | 'ORDER_TIMEOUT' | 'VISIT_REMINDER' | 'PAYMENT_REMINDER'

export interface MessageItem {
  /** 消息 ID（字符串，防精度丢失） */
  id: string
  type: MessageType
  title: string
  content: string
  /** 关联订单 ID（字符串，防精度丢失），可跳订单记录 */
  bizId: string | null
  /** 0 未读 1 已读 */
  isRead: number
  /** yyyy-MM-dd HH:mm:ss */
  createdAt: string
}

// ============== 后台管理（仅管理端使用，鸿蒙端做预留）==============
export interface AdminUserRequest {
  phone: string
  nickname: string
  /** 新增必填，编辑留空不改 */
  password?: string
}

export interface AdminUserResponse {
  id: number
  phone: string
  nickname: string
  userType: UserType
  status: 0 | 1
  createdAt: string
  lastLoginAt?: string
}

export interface DoctorScheduleRuleBrief {
  id: number
  ruleName: string
  scheduleOverview: string[]
}

export interface AdminDoctorRequest {
  name: string
  departmentId: number
  title?: string
  introduction?: string
  levelIds?: number[]
  scheduleRuleIds?: number[]
}

export interface AdminDoctorResponse {
  id: number
  name: string
  departmentId: number
  departmentName: string
  title: string
  introduction: string
  enabled: 0 | 1
  levelIds: number[]
  scheduleRules: DoctorScheduleRuleBrief[]
}

export interface Department {
  id: number
  code: string
  name: string
  /** 上级科室 ID，0 表示一级科室 */
  parentId: number
  departmentType: string
  description: string
  sortNo: number
  enabled: 0 | 1
  /** 响应展示字段，新增/编辑时不传 */
  parentName?: string
  createdAt?: string
  updatedAt?: string
}

export interface ScheduleRule {
  id: number
  levelId: number
  ruleName: string
  /** 7 位二进制位掩码，21 = 10101 = 周一/三/五 */
  weekdayMask: number
  period: 'MORNING' | 'AFTERNOON' | 'EVENING' | string
  /** 时段 JSON：[{"start":"08:00","end":"08:30","quota":4}] */
  slotsJson: string
  effectiveStart: string
  effectiveEnd?: string
  enabled: 0 | 1
  /** 响应展示字段 */
  ruleCode?: string
  scheduleOverview?: string[]
  createdAt?: string
  updatedAt?: string
}

export interface RegistrationLevel {
  id: number
  code: string
  name: string
  /** 单位分 */
  feeFen: number
  defaultQuota: number
  sortNo: number
  enabled: 0 | 1
  createdAt?: string
  updatedAt?: string
}

// ============== 鸿蒙 UI 侧常用小类型 ==============
/** 通用选项（用于下拉/单选弹框）*/
export interface OptionItem<T = string | number> {
  label: string
  value: T
}

/** Banner / 快捷入口 / 推荐医生 等卡片的通用展示类型 */
export interface BannerItem {
  id: string | number
  title?: string
  image: string
  linkUrl?: string
}
export interface QuickEntryItem {
  key: 'book' | 'orders' | 'contacts' | 'ai' | string
  label: string
  iconFont: string        // 预留 iconfont 名；目前用符号占位渲染圆形卡片
  route: string
  routeParams?: Record<string, Object>
}
