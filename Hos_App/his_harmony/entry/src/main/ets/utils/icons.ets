/**
 * 全局 symbol 图标常量（AppIcon）。
 * - 值统一为 HarmonyOS 系统符号资源名（sys.symbol.xxx），配合 SymbolGlyph($r(AppIcon.xxx)) 使用；
 * - 所有名称均来自 SDK 系统符号表（toolchains/id_defined.json，type=symbol），保证编译期可解析；
 * - 页面/组件只允许引用这里的常量，禁止散落写 'sys.symbol.xxx' 字面量，便于统一换图标。
 */
export class AppIcon {
  /** 首页/科室：搜索放大镜 */
  static readonly search: string = 'sys.symbol.magnifyingglass'
  /** 空状态：空箱子（暂无数据/暂无记录） */
  static readonly emptyBox: string = 'sys.symbol.archivebox'
  /** 展开：向下箭头 */
  static readonly dropDown: string = 'sys.symbol.chevron_down'
  /** 进入/更多：向右箭头 */
  static readonly forward: string = 'sys.symbol.chevron_right'
  /** 设置：齿轮 */
  static readonly settings: string = 'sys.symbol.gearshape'
  /** AI 对话：灯泡 */
  static readonly lightbulb: string = 'sys.symbol.lightbulb'
  /** AI 发送：纸飞机 */
  static readonly send: string = 'sys.symbol.paperplane'
  /** 底部 Tab / 首页入口：首页房子 */
  static readonly homeOutline: string = 'sys.symbol.house'
  /** 预约挂号：日历 */
  static readonly appointmentOutline: string = 'sys.symbol.calendar'
  /** 挂号记录：消息气泡 */
  static readonly message: string = 'sys.symbol.message'
  /** 我的/就诊人：人像 */
  static readonly profileOutline: string = 'sys.symbol.person'
  /** AI 咨询 / AI Tab：魔法棒星星 */
  static readonly aiOutline: string = 'sys.symbol.wand_and_stars'
  /** 挂号成功：对勾圆圈（实心） */
  static readonly success: string = 'sys.symbol.checkmark_circle_fill'
  /** 编辑：方框铅笔 */
  static readonly edit: string = 'sys.symbol.square_and_pencil'
  /** 删除：垃圾桶 */
  static readonly delete: string = 'sys.symbol.trash'
}
