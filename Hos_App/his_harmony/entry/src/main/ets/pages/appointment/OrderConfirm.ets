/**
 * 【订单确认】交付负责人：成员 C
 * 入参：slotId（必填）、contactId（必填）
 * 流程：确认信息 → 立即支付（createOrder → payOrder）→ 成功跳 BookingSuccess
 */
import router from '@ohos.router'
import type { OrderDetail, SlotSummary, PatientContact, CreateOrderRequest } from '../../types'
import * as contactApi from '../../api/contact'
import * as orderApi from '../../api/order'
import { FeeTag } from '../../components/FeeTag'
import { AvatarIcon } from '../../components/AvatarIcon'
import { AppBar } from '../../components/AppBar'
import { PrimaryButton } from '../../components/PrimaryButton'
import { Format } from '../../utils/format'
import { Route } from '../../utils/theme'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct OrderConfirm {
  @State slotId: number = 0
  @State contactId: number = 0
  @State slot?: SlotSummary
  @State contact?: PatientContact
  @State paying: boolean = false

  async aboutToAppear(): Promise<void> {
    const p: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined
    if (!p) return
    this.slotId = Number(p['slotId']); this.contactId = Number(p['contactId'])
    // 信息展示：走 slot 接口 + contact 列表（slot 没有按 slotId 查询，这里偷懒用 departmentId+date 拉匹配）
    // TODO 成员 C：后端加 GET /api/slots/{slotId} 最干净；没加就用 listSlots 取到当日再 find
    const contacts: PatientContact[] = await contactApi.listContacts()
    this.contact = contacts.find((c: PatientContact) => c.id === this.contactId)
  }

  private async pay(): Promise<void> {
    if (this.paying) return
    this.paying = true
    try {
      const req: CreateOrderRequest = {
        slotId: this.slotId,
        contactId: this.contactId,
        idempotencyKey: Format.uuid()
      }
      const created: OrderDetail = await orderApi.createOrder(req)
      const paid: OrderDetail = await orderApi.payOrder(created.id)
      // 到预约成功页
      router.replaceUrl({ url: Route.BOOK_SUCCESS, params: { orderId: String(paid.id) } })
    } catch(e: Error) { /* toast 已弹 */ }
    finally { this.paying = false }
  }

  build() {
    Column() {
      AppBar({ title:'确认预约' })
      // 医院 / 科室 / 医生信息卡
      Column() {
        Text('东软云医院').fontSize(18).fontWeight(700).alignSelf(ItemAlign.Start)
        if (this.slot) {
          Row() { AvatarIcon({name:this.slot.doctorName,size:52}).margin({right:12})
            Column() {
              Text(this.slot.doctorName).fontSize(16).fontWeight(600)
              Text(`${this.slot.levelName} · ${Format.date(this.slot.visitDate)} ${Format.time(this.slot.startTime)}-${Format.time(this.slot.endTime)}`)
                .fontSize(13).fontColor($r('app.color.text_secondary')).margin({top:4})
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            FeeTag({ fen: this.slot.feeFen, type:'secondary', size:'lg' })
          }.margin({top:12})
        } else { Text('加载号源信息…').fontColor($r('app.color.text_hint')).margin({top:12}) }
      }.width('92%').padding(16).margin({top:16})
       .backgroundColor($r('app.color.bg_card')).borderRadius(16)

      // 就诊人卡
      Column() {
        Text('就诊人').fontSize(16).fontWeight(700).alignSelf(ItemAlign.Start)
        if (this.contact) {
          Row() { AvatarIcon({name:this.contact.name,size:44}).margin({right:12})
            Column() {
              Text(this.contact.name).fontSize(15).fontWeight(600)
              Text(`${Format.maskPhone(this.contact.phone)} · ${this.contact.relation}`)
                .fontSize(12).fontColor($r('app.color.text_hint')).margin({top:4})
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          }.margin({top:12})
        }
      }.width('92%').padding(16).margin({top:12})
       .backgroundColor($r('app.color.bg_card')).borderRadius(16)

      Blank().layoutWeight(1)

      Row() {
        Column() {
          Text('支付金额').fontSize(12).fontColor($r('app.color.text_hint'))
          if (this.slot) { FeeTag({ fen: this.slot.feeFen, type:'danger', size:'lg' }).margin({top:4}) }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        PrimaryButton({ label:'立即支付', enabled:!this.paying, onClick:() => this.pay() }).width(180)
      }
      .width('100%').padding(16)
      .backgroundColor($r('app.color.bg_card'))
      .borderWidth({top:0.5}).borderColor($r('app.color.divider'))
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
