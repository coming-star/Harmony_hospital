/**
 * 听诊器图标组件（直接加载本地图片替换原手绘Logo）。
 * 支持自定义大小。保留 color 参数以兼容现有调用。
 */
@Component
export struct StethoscopeIcon {
  @Prop customSize: number = 120
  // 这里补回 color，虽然图片本身改不了颜色，但不会报错了
  @Prop color: ResourceColor = $r('app.color.primary')

  build() {
    Stack() {
      // 直接加载项目里的 startIcon.png
      Image($r('app.media.startIcon'))
        .width(this.customSize)
        .height(this.customSize)
        .objectFit(ImageFit.Contain)
    }
    .width(this.customSize)
    .height(this.customSize)
  }
}