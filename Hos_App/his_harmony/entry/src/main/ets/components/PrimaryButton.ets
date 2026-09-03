/**
 * 品牌蓝圆角大按钮（参考图登录/注册页的蓝色主按钮）。
 * - 高度 52vp，圆角 16vp
 * - 默认占满父容器 width='100%'
 * - 支持三种变体：primary 蓝（默认）/ danger 红 / light 蓝底白边蓝字
 *
 * 用法：PrimaryButton({ label:'登录', onClick:() => submit() })
 */
type Variant = 'primary' | 'danger' | 'light'

@Component
export struct PrimaryButton {
  @Prop label: string = '按钮'
  @Prop variant: Variant = 'primary'
  @Prop enabled: boolean = true
  @Prop height: number | string = 52
  @Link? onClick?: () => void

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
  private border(): ResourceColor {
    return this.variant === 'light' ? $r('app.color.primary') : Color.Transparent
  }

  build() {
    Row() {
      Text(this.label)
        .fontSize($r('app.float.fs_18'))
        .fontWeight(600)
        .fontColor(this.enabled ? this.fg() : $r('app.color.text_white'))
        .opacity(this.enabled ? 1.0 : 0.55)
    }
    .width('100%')
    .height(this.height)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.enabled ? this.bg() : $r('app.color.disabled'))
    .borderRadius($r('app.float.radius_lg'))
    .borderWidth(1).borderColor(this.border())
    .onClick(() => { if (this.enabled && this.onClick) this.onClick() })
  }
}
