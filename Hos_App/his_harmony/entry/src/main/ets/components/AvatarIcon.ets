/**
 * 医生/用户头像组件：
 *   传了图片就显示图片（圆角），否则显示首字母圆形背景（主色/辅色AI智能配色）
 *
 * 用法：
 *   AvatarIcon({ name: '陈明远', size: 48 })
 *   AvatarIcon({ url: doctor.avatarUrl, size: 60 })
 */
@Component
export struct AvatarIcon {
  @Prop name: string = ''
  @Prop url: string = ''
  @Prop iconSize: number | string = 48
  /** 手动指定背景色（主色），不传则按名字 hash */
  @Prop bg: ResourceColor | undefined = undefined

  private pickBg(): ResourceColor {
    if (this.bg) return this.bg
    const palette: ResourceColor[] = [
      $r('app.color.primary'),
      $r('app.color.secondary_booking'),
      $r('app.color.secondary_ai'),
      $r('app.color.success'),
      $r('app.color.warning')
    ]
    let h: number = 0
    for (let i: number = 0; i < this.name.length; i++) h = (h * 31 + this.name.charCodeAt(i)) | 0
    const idx: number = Math.abs(h) % palette.length
    return palette[idx]
  }

  private initial(): string {
    if (!this.name) return '?'
    const first: string = this.name.trim().charAt(0)
    return first.toUpperCase()
  }

  private pickFontSize(): Length {
    return typeof this.iconSize === 'number' ? (this.iconSize as number) * 0.42 : '42%'
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.url && this.url.length > 0) {
        Image(this.url)
          .width(this.iconSize)
          .height(this.iconSize)
          .borderRadius(9999)
          .objectFit(ImageFit.Cover)
          .backgroundColor($r('app.color.primary_light'))
      } else {
        Circle()
          .width(this.iconSize)
          .height(this.iconSize)
          .fill(this.pickBg())
        Text(this.initial())
          .fontSize(this.pickFontSize())
          .fontColor($r('app.color.text_white'))
          .fontWeight(FontWeight.Bold)
      }
    }
    .width(this.iconSize)
    .height(this.iconSize)
  }
}
