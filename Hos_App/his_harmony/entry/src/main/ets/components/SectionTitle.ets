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
        .width($r('app.float.sp_4'))
        .height($r('app.float.fs_18'))
        .backgroundColor($r('app.color.primary'))
        .borderRadius($r('app.float.radius_sm'))
        .margin({ right: $r('app.float.sp_8') })

      Text(this.title)
        .fontSize($r('app.float.fs_18'))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.titleColor)
        .layoutWeight(1)

      if (this.moreText && this.moreText.length > 0) {
        Row() {
          Text(this.moreText)
            .fontSize($r('app.float.fs_14'))
            .fontColor($r('app.color.text_hint'))
          Text(' ›')
            .fontSize($r('app.float.fs_16'))
            .fontColor($r('app.color.text_hint'))
        }
        .padding({ left: $r('app.float.sp_8'), right: $r('app.float.sp_8') })
        .height($r('app.float.btn_height_sm'))
        .onClick(() => this.onMore && this.onMore())
      }
    }
    .width('100%')
    .padding({
      left: $r('app.float.sp_16'), right: $r('app.float.sp_8'),
      top: $r('app.float.sp_4'), bottom: $r('app.float.sp_8')
    })
  }
}
