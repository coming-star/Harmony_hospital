/**
 * 品牌蓝圆角大按钮（参考图登录/注册页的蓝色主按钮）。
 * - 高度 52vp，圆角 16vp
 * - 默认占满父容器 width='100%'
 * - 支持三种变体：primary 蓝（默认）/ danger 红 / light 蓝底白边蓝字
 *
 * 用法：PrimaryButton({ label:'登录', onTap:() => submit() })
 */
type Variant = 'primary' | 'danger' | 'light'

@Component
export struct PrimaryButton {
  @Prop label: string = '按钮'
  @Prop variant: Variant = 'primary'
  @Prop isEnabled: boolean = true
  @Prop btnHeight: number | string = 60
  onTap?: () => void

  private bg(): ResourceColor {
    switch (this.variant) {
      case 'danger': return $r('app.color.danger')
      case 'light':  return $r('app.color.primary_light')
      case 'primary':
      default:       return $r('app.color.primary')
    }
  }
  private fg(): ResourceColor {
    switch (this.variant) {
      case 'light':  return $r('app.color.primary')
      default:       return $r('app.color.text_white')
    }
  }
  private getBorderColor(): ResourceColor {
    return this.variant === 'light' ? $r('app.color.primary') : Color.Transparent
  }

  build() {
    Row() {
      Text(this.label)
        .fontSize($r('app.float.fs_24'))
        .fontWeight(600)
        .fontColor(this.isEnabled ? this.fg() : $r('app.color.text_white'))
        .opacity(this.isEnabled ? 1.0 : 0.55)
    }
    .width('100%')
    .height(this.btnHeight)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.isEnabled ? this.bg() : $r('app.color.disabled'))
    .borderRadius($r('app.float.radius_lg'))
    .borderWidth(1).borderColor(this.getBorderColor())
    .onClick(() => { if (this.isEnabled && this.onTap) this.onTap() })
  }
}
