/**
 * 分组标题组件：左边主色小竖条 + 文字标题 + 可选"查看全部"尾部按钮
 *
 * 用法：
 *   SectionTitle({ title: '推荐科室', moreText: '查看全部', onMore: ()=> router.pushUrl(...) })
 */
@Component
export struct SectionTitle {
  @Prop title: string = ''
  /** 传了就显示"查看全部"（或自定义文字）按钮 */
  @Prop moreText: string = ''
  @Prop titleColor: ResourceColor = $r('app.color.text_primary')
  onMore?: () => void

  build() {
    Row() {
      Row()
        .width(4)
        .height(23)
        .backgroundColor($r('app.color.primary'))
        .borderRadius($r('app.float.radius_sm'))
        .margin({ right: 8 })

      Text(this.title)
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .layoutWeight(1)

      if (this.moreText && this.moreText.length > 0) {
        Row() {
          Text(this.moreText)
            .fontSize(23)
            .fontColor($r('app.color.text_hint'))
          Text(' ›')
            .fontSize(23)
            .fontColor($r('app.color.text_hint'))
        }
        .padding({ left: 8, right: 8 })
        .height(36)
        .onClick(() => this.onMore && this.onMore())
      }
    }
    .width('100%')
    .padding({
      left: 20, right: 12,
      top: 24, bottom: 10
    })
  }
}
