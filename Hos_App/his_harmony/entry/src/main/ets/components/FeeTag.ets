/**
 * 金额标签：后端分 → 前端元展示（自动除 100 + ¥ 前缀 + 主色字体）
 *
 * 用法：FeeTag({ fen: order.amountFen, type: 'primary', size: 'lg' })
 */
import { Format } from '../utils/format'

type FeeType = 'primary' | 'danger' | 'secondary' | 'gray'
type FeeSize = 'sm' | 'md' | 'lg'

@Component
export struct FeeTag {
  /** 后端金额，单位：分 */
  @Prop fen: number = 0
  @Prop type: FeeType = 'primary'
  @Prop iconSize: FeeSize = 'md'
  /** 是否显示 ¥ 前缀 */
  @Prop withPrefix: boolean = true

  private pickColor(): ResourceColor {
    switch (this.type) {
      case 'danger':    return $r('app.color.danger')
      case 'secondary': return $r('app.color.secondary_booking')
      case 'gray':      return $r('app.color.text_secondary')
      case 'primary':
      default:          return $r('app.color.primary')
    }
  }
  private pickFont(): number {
    switch (this.iconSize) {
      case 'lg': return 24
      case 'sm': return 18
      case 'md':
      default:   return 20
    }
  }

  build() {
    Row() {
      Text(Format.yuan(this.fen, this.withPrefix))
        .fontColor(this.pickColor())
        .fontSize(this.pickFont())
        .fontWeight(FontWeight.Bold)
    }
  }
}
