/**
 * 听诊器图标组件（参考图登录/注册页正中大 Logo）。
 * 用 ArkUI 形状/线条画一个，不依赖图片资源。蓝线 + 浅蓝圆角底。
 *
 * 用法：StethoscopeIcon({ size: 120 })
 */
@Component
export struct StethoscopeIcon {
  @Prop size: number = 120

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 浅蓝圆角正方形底
      Stack() { Blank() }.width(this.size).height(this.size).borderRadius(Math.floor(this.size * 0.3)).backgroundColor($r('app.color.stethoscope_bg'))
      // 听诊器图形（用 CanvasPath 太复杂，简版用两个同心圆 + 一竖线 + 两个圆环 = 足够形似参考图蓝 logo）
      Column() {
        // 两个耳朵圆圈（左右）
        Row() {
          Circle({ width: this.size * 0.10, height: this.size * 0.10 })
            .stroke($r('app.color.primary')).strokeWidth(4)
            .fill(Color.Transparent)
            .margin({ right: this.size * 0.36 })
          Circle({ width: this.size * 0.10, height: this.size * 0.10 })
            .stroke($r('app.color.primary')).strokeWidth(4)
            .fill(Color.Transparent)
        }
        // 听筒大圆
        Circle({ width: this.size * 0.28, height: this.size * 0.28 })
          .stroke($r('app.color.primary')).strokeWidth(5)
          .fill(Color.Transparent)
          .margin({ top: this.size * 0.10 })
      }
      .width(this.size).height(this.size)
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    }
    .width(this.size).height(this.size)
  }
}
