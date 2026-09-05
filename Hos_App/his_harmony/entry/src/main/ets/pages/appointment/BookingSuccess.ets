/**
 * 【预约成功】交付负责人：成员 C
 * 入参：orderId（必填）—— 从页面参数拿；若拿不到走"返回首页"兜底
 */
import router from '@ohos.router'
import type { OrderDetail } from '../../types'
import { OrderStatusValue } from '../../types'
import * as orderApi from '../../api/order'
import { AppIcon } from '../../utils/icons'
import { Format } from '../../utils/format'
import { Route } from '../../utils/theme'
import { FeeTag } from '../../components/FeeTag'
import { StatusTag } from '../../components/StatusTag'
import { AppBar } from '../../components/AppBar'
import { PrimaryButton } from '../../components/PrimaryButton'

@Entry
@Component
struct BookingSuccess {
  @State order: OrderDetail | undefined = undefined

  async aboutToAppear(): Promise<void> {
    const p: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined
    if (p && p['orderId']) {
      try { this.order = await orderApi.getOrder(String(p['orderId'])) } catch (_) {}
    }
  }

  private goRecord(): void { router.replaceUrl({ url: Route.ORDER_RECORD }) }
  private goHome(): void   { router.replaceUrl({ url: Route.HOME }) }

  /** 已支付 → 支付成功；未支付（如稍后支付）→ 预约成功 */
  private successTitle(): string {
    return this.order !== undefined && this.order.status === OrderStatusValue.PAID ? '支付成功！' : '预约成功！'
  }
  private appBarTitle(): string {
    return this.order !== undefined && this.order.status === OrderStatusValue.PAID ? '支付成功' : '预约成功'
  }

  build() {
    Column() {
      AppBar({ title: this.appBarTitle(), hideBack: true })
      Column() {
        // checkmark_circle_fill 符号本身自带实心圆底，直接放大上色即可，勿再套圆环容器（会偏心）
        SymbolGlyph($r(AppIcon.success))
          .fontSize(96)
          .fontColor([$r('app.color.success')])
          .margin({bottom:16})
        Text(this.successTitle()).fontSize(28).fontWeight(800)
          .fontColor($r('app.color.text_primary')).margin({bottom:8})
        if (this.order) {
          Text(`订单号：${this.order.orderNo}`).fontSize(21)
            .fontColor($r('app.color.text_hint'))
        }
      }.margin({top:40,bottom:20}).alignItems(HorizontalAlign.Center)

      if (this.order) {
        Column() {
          Row() { Text('订单状态').layoutWeight(1).fontSize(22).fontColor($r('app.color.text_secondary'))
                 StatusTag({ status: this.order!.status }) }
            .margin({bottom:14})
          this.KV('医院', '东软云医院')
          this.KV('科室', `${this.order!.departmentName}`)
          this.KV('医生', `${this.order!.doctorName} (${this.order!.levelName})`)
          this.KV('就诊时间', `${Format.date(this.order!.visitDate)} ${Format.time(this.order!.startTime)}-${Format.time(this.order!.endTime)}`)
          this.KV('就诊人', `${this.order!.contactName} (${Format.maskPhone(this.order!.contactPhone)})`)
          Row() { Text('支付金额').layoutWeight(1).fontSize(22).fontColor($r('app.color.text_secondary'))
                 FeeTag({ fen: this.order!.amountFen, type:'primary', iconSize:'md' }) }
            .margin({top:14})
        }
        .width('92%').padding(20).backgroundColor($r('app.color.bg_card')).borderRadius(16)
      }

      Blank().layoutWeight(1)

      Row() {
        PrimaryButton({ label:'查看挂号记录', variant:'light', onTap:() => this.goRecord() })
          .width('45%').margin({right:12})
        PrimaryButton({ label:'返回首页', variant:'primary', onTap:() => this.goHome() })
          .width('45%')
      }.padding(16)
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .alignItems(HorizontalAlign.Center)
  }

  @Builder KV(k: string, v: string) {
    Row() {
      Text(k).layoutWeight(1).fontSize(22).fontColor($r('app.color.text_secondary'))
      Text(v).fontSize(22).fontColor($r('app.color.text_primary'))
    }.margin({top:14})
  }
}
