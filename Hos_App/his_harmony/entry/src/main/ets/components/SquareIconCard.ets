/**
 * 首页/我的页等使用的「方形图标」组件（参考图首页的 4 个入口 + 我的页 3 张入口卡）。
 * 由一个大圆角方形背景（底色 bg）+ 符号/简笔画（glyph）+ 下方文字（label + sub） 组成。
 *   SquareIconCard({ glyph:'📅', label:'在线挂号', bg:'#E8F1FC', fg:'#0A66C2', onTap:()=>{} })
 */
@Component
export struct SquareIconCard {
  @Prop glyph: string = '📋'
  @Prop label: string = ''
  @Prop sub: string = ''
  @Prop bg: ResourceColor = $r('app.color.primary_light')
  @Prop fg: ResourceColor = $r('app.color.primary')
  @Prop iconSize: number = 88
  onTap?: () => void

  build() {
    Column() {
      Text(this.glyph).fontSize(this.iconSize * 0.40)
        .width(this.iconSize).height(this.iconSize)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.bg)
        .borderRadius($r('app.float.radius_md'))
      Text(this.label)
        .fontSize($r('app.float.fs_14'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(500)
        .margin({ top: 8 })
      if (this.sub && this.sub.length > 0) {
        Text(this.sub)
          .fontSize($r('app.float.fs_12'))
          .fontColor($r('app.color.text_hint'))
          .margin({ top: 2 })
      }
    }
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .onClick(() => { if (this.onTap) this.onTap() })
  }
}
