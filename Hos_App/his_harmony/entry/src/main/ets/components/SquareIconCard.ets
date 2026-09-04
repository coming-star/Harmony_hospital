/**
 * 首页/我的页等使用的「方形图标」组件（参考图首页的 4 个入口 + 我的页 3 张入口卡）。
 * 由一个大圆角方形背景（底色 bg）+ symbol 图标（icon）+ 下方文字（label + sub） 组成。
 *   SquareIconCard({ icon: AppIcon.appointmentOutline, label: '在线挂号', bg: $r('app.color.primary_light'), fg: $r('app.color.primary'), onTap: ()=>{} })
 */
import { AppIcon } from '../utils/icons'

@Component
export struct SquareIconCard {
  @Prop icon: string = AppIcon.emptyBox
  @Prop label: string = ''
  @Prop sub: string = ''
  @Prop bg: ResourceColor = $r('app.color.primary_light')
  @Prop fg: ResourceColor = $r('app.color.primary')
  @Prop iconSize: number = 88
  onTap?: () => void

  build() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(this.iconSize)
          .height(this.iconSize)
          .backgroundColor(this.bg)
          .borderRadius($r('app.float.radius_md'))
        SymbolGlyph($r(this.icon))
          .fontSize(this.iconSize * 0.40)
      }
      .width(this.iconSize)
      .height(this.iconSize)
      Text(this.label)
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))
        .fontWeight(500)
        .margin({ top: 8 })
      if (this.sub && this.sub.length > 0) {
        Text(this.sub)
          .fontSize(14)
          .fontColor($r('app.color.text_hint'))
          .margin({ top: 2 })
      }
    }
    .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
    .onClick(() => { if (this.onTap) this.onTap() })
  }
}
