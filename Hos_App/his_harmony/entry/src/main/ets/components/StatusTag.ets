/**
 * 订单状态胶囊标签：4 种配色（跟后端 OrderStatus 枚举一一对应）
 * - PENDING_PAYMENT 待支付：橙底橙字
 * - PAID 已支付：绿底绿字
 * - COMPLETED 已完成：蓝底蓝字
 * - CANCELLED 已取消：灰底灰字
 *
 * 用法：StatusTag({ status: order.status })
 */
import { OrderStatus, OrderStatusText } from '../types'

@Component
export struct StatusTag {
  @Prop status: OrderStatus | string = OrderStatus.PENDING_PAYMENT

  private pair(): { bg: ResourceColor; fg: ResourceColor; label: string } {
    switch (this.status) {
      case OrderStatus.PAID:
        return { bg: $r('app.color.success_light'),
                 fg: $r('app.color.success'), label: OrderStatusText.PAID }
      case OrderStatus.COMPLETED:
        return { bg: $r('app.color.secondary_booking_light'),
                 fg: $r('app.color.secondary_booking'), label: OrderStatusText.COMPLETED }
      case OrderStatus.CANCELLED:
        return { bg: $r('app.color.disabled_light'),
                 fg: $r('app.color.text_hint'), label: OrderStatusText.CANCELLED }
      case OrderStatus.PENDING_PAYMENT:
      default:
        return { bg: $r('app.color.warning_light'),
                 fg: $r('app.color.warning'), label: OrderStatusText.PENDING_PAYMENT }
    }
  }

  build() {
    Text(this.pair().label)
      .fontSize($r('app.float.fs_12'))
      .fontColor(this.pair().fg)
      .padding({
        left: $r('app.float.sp_12'),
        right: $r('app.float.sp_12'),
        top: 4,
        bottom: 4
      })
      .backgroundColor(this.pair().bg)
      .borderRadius($r('app.float.radius_pill'))
  }
}
