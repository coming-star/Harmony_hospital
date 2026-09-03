/**
 * AppBar 顶部导航栏组件（所有非 Tabs 子页面必加）。
 * - 高度 56vp；背景品牌蓝 + 白色大标题
 * - 左侧"‹"返回箭头（点击自动 router.back()；传 hideBack=true 时不显示）
 * - 右侧可选「图标按钮」（如设置/搜索）
 *
 * 用法：
 *   AppBar({ title: '选择科室' })
 *   AppBar({ title: '登录', hideBack: true })
 *   AppBar({ title: 'AI健康管家', rightIcon: '⚙️', onRightClick: () => openSettings() })
 */
import router from '@ohos.router'

@Component
export struct AppBar {
  @Prop title: string = ''
  @Prop hideBack: boolean = false
  /** 右侧图标（简单做法用字符串占位，如 ⚙️ / 🔍 / 🩺；正式版替换 SymbolGlyph 或 PNG）*/
  @Prop rightIcon?: string
  @Link? onRightClick?: () => void

  build() {
    Row() {
      if (!this.hideBack) {
        Text('‹').fontSize(32).fontColor($r('app.color.text_white')).fontWeight(300)
          .width(40).height(40).textAlign(TextAlign.Center)
          .margin({ left: $r('app.float.sp_4') })
          .onClick(() => { try { router.back() } catch(_) {} })
      } else {
        Blank().width(40).height(40)
      }

      Text(this.title)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize($r('app.float.fs_20'))
        .fontWeight(700)
        .fontColor($r('app.color.text_white'))
        .margin({ right: this.hideBack ? 40 : 0 })

      if (this.rightIcon && this.rightIcon.length > 0) {
        Text(this.rightIcon).fontSize(22).fontColor($r('app.color.text_white'))
          .width(40).height(40).textAlign(TextAlign.Center)
          .onClick(() => { if (this.onRightClick) this.onRightClick() })
      } else if (!this.hideBack) {
        Blank().width(40).height(40)
      }
    }
    .width('100%')
    .height($r('app.float.app_bar_height'))
    .backgroundColor($r('app.color.primary'))
  }
}
