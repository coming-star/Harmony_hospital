/**
 * 【模拟收银台】
 * 入参：orderId（必填）、orderNo、amountFen
 * 流程：选择支付方式（模拟）→ 确认支付（payOrder，后端订单状态置为已支付）→ 支付成功跳 BookingSuccess
 * 返回本页 = 暂不支付，订单保持待支付（可稍后在挂号记录里继续支付）
 */
import router from '@ohos.router'
import * as orderApi from '../../api/order'
import { AppBar } from '../../components/AppBar'
import { PrimaryButton } from '../../components/PrimaryButton'
import { FeeTag } from '../../components/FeeTag'
import { Route } from '../../utils/theme'

interface PayChannel {
  key: string
  name: string
  desc: string
}

@Entry
@Component
struct PayPage {
  /** 订单 ID 为雪花大整数，按字符串传递（禁止 Number() 转换，会丢精度） */
  @State orderId: string = ''
  @State orderNo: string = ''
  @State amountFen: number = 0
  @State channel: string = 'ALIPAY'
  @State paying: boolean = false
  private readonly channels: PayChannel[] = [
    { key: 'ALIPAY', name: '支付宝', desc: '模拟支付，秒到账' },
    { key: 'WECHAT', name: '微信支付', desc: '模拟支付，秒到账' }
  ]

  aboutToAppear(): void {
    const p: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined
    if (p) {
      this.orderId = String(p['orderId'] ?? '')
      this.orderNo = String(p['orderNo'] ?? '')
      this.amountFen = Number(p['amountFen'] ?? 0)
    }
  }

  private async confirmPay(): Promise<void> {
    if (this.paying || !this.orderId) return
    this.paying = true
    try {
      await orderApi.payOrder(this.orderId)
      // 支付成功 → 支付成功页（替换收银台，避免返回又回到收银台）
      router.replaceUrl({ url: Route.BOOK_SUCCESS, params: { orderId: String(this.orderId) } })
    } catch (_) { /* request.ets 已统一 toast */ }
    finally { this.paying = false }
  }

  build() {
    Column() {
      AppBar({ title: '收银台' })

      // 金额卡
      Column() {
        Text('支付金额').fontSize(20).fontColor($r('app.color.text_hint'))
        FeeTag({ fen: this.amountFen, type: 'danger', iconSize: 'lg' }).margin({ top: 10 })
        if (this.orderNo !== '') {
          Text(`订单号：${this.orderNo}`).fontSize(16).fontColor($r('app.color.text_hint')).margin({ top: 10 })
        }
      }
      .width('92%').padding(24).margin({ top: 16 })
      .backgroundColor($r('app.color.bg_card')).borderRadius(16)
      .alignItems(HorizontalAlign.Center)

      // 支付方式
      Column() {
        ForEach(this.channels, (c: PayChannel, idx: number) => {
          Row() {
            Column() {
              Text(c.name).fontSize(22).fontWeight(600).fontColor($r('app.color.text_primary'))
              Text(c.desc).fontSize(16).fontColor($r('app.color.text_hint')).margin({ top: 4 })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)

            Radio({ value: c.key, group: 'payChannel' })
              .checked(this.channel === c.key)
              .onChange((checked: boolean) => { if (checked) this.channel = c.key })
          }
          .width('100%').padding(18)
          .onClick(() => { this.channel = c.key })

          if (idx < this.channels.length - 1) {
            Divider().color($r('app.color.divider')).margin({ left: 18, right: 18 })
          }
        })
      }
      .width('92%').margin({ top: 12 })
      .backgroundColor($r('app.color.bg_card')).borderRadius(16)

      Blank().layoutWeight(1)

      PrimaryButton({
        label: this.paying ? '支付中…' : '确认支付',
        isEnabled: !this.paying,
        onTap: () => this.confirmPay()
      }).width('92%').margin({ bottom: 20 })
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
