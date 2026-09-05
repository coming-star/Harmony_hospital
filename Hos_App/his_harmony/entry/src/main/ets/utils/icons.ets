/**
 * SymbolGlyph 系统图标资源名集合（组长的视觉重构里引用了 AppIcon，但漏提交了这个文件，先补上）。
 * 用法：SymbolGlyph($r(AppIcon.xxx))
 * 说明：值为 HarmonyOS 内置符号资源名 sys.symbol.xxx；若某个图标显示空白，说明该资源名不对，
 *       请查 DevEco 的 SymbolGlyph 资源列表后修正对应项。
 */
export class AppIcon {
  static readonly homeOutline: string = 'sys.symbol.house'
  static readonly appointmentOutline: string = 'sys.symbol.calendar'
  static readonly aiOutline: string = 'sys.symbol.ellipsis_bubble'
  static readonly profileOutline: string = 'sys.symbol.person'
  static readonly settings: string = 'sys.symbol.gearshape'
  static readonly search: string = 'sys.symbol.magnifyingglass'
  static readonly emptyBox: string = 'sys.symbol.shippingbox'
  static readonly dropDown: string = 'sys.symbol.chevron_down'
  static readonly forward: string = 'sys.symbol.chevron_right'
  static readonly lightbulb: string = 'sys.symbol.lightbulb'
  static readonly send: string = 'sys.symbol.paperplane'
  static readonly success: string = 'sys.symbol.checkmark_circle'
  static readonly delete: string = 'sys.symbol.trash'
  static readonly edit: string = 'sys.symbol.pencil'
  static readonly message: string = 'sys.symbol.message'

}

