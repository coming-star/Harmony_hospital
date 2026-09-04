/**
 * 听诊器图标组件（参考图登录/注册页正中大 Logo，以及首页科室卡片）。
 * 用 ArkUI 形状/线条画一个，不依赖图片资源。支持自定义大小和颜色。
 *
 * 用法：
 *   StethoscopeIcon({ size: 120 })
 *   StethoscopeIcon({ size: 20, color: $r('app.color.text_white') })
 */
@Component
export struct StethoscopeIcon {
  @Prop customSize: number = 120
  @Prop color: ResourceColor = $r('app.color.primary')

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 浅蓝圆角正方形底
      Column().width(this.customSize).height(this.customSize).borderRadius(Math.floor(this.customSize * 0.3)).backgroundColor($r('app.color.stethoscope_bg'))
      // 听诊器图形（用 CanvasPath 太复杂，简版用两个同心圆 + 一竖线 + 两个圆环 = 足够形似参考图蓝 logo）
      Column() {
        // 两个耳朵圆圈（左右）
        Row() {
          Circle({ width: this.customSize * 0.10, height: this.customSize * 0.10 })
            .stroke(this.color).strokeWidth(4)
            .fill(Color.Transparent)
            .margin({ right: this.customSize * 0.36 })
          Circle({ width: this.customSize * 0.10, height: this.customSize * 0.10 })
            .stroke(this.color).strokeWidth(4)
            .fill(Color.Transparent)
        }
        // 听筒大圆
        Circle({ width: this.customSize * 0.28, height: this.customSize * 0.28 })
          .stroke(this.color).strokeWidth(5)
          .fill(Color.Transparent)
          .margin({ top: this.customSize * 0.10 })
      }
      .width(this.customSize).height(this.customSize)
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
    .width(this.customSize).height(this.customSize)
  }
}
