/**
 * 【订单确认】交付负责人：成员 C
 * 入参：slotId（必填）、contactId（必填）
 * 流程：确认信息 → 确认预约（createOrder，延后支付）→ 成功跳 BookingSuccess
 */
import router from '@ohos.router'
import type { OrderDetail, SlotSummary, PatientContact, CreateOrderRequest } from '../../types'
import { relationText } from '../../types'
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
  @State slot: SlotSummary | undefined = undefined
  @State contact: PatientContact | undefined = undefined
  @State paying: boolean = false

  async aboutToAppear(): Promise<void> {
    const p: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined
    if (!p) return
    this.slotId = Number(p['slotId']); this.contactId = Number(p['contactId'])
    // 从路由参数恢复号源信息（前端传参，绕开"后端无按 slotId 查号源接口"）
    if (p['doctorName']) {
      this.slot = {
        slotId: this.slotId,
        doctorId: 0,
        doctorName: String(p['doctorName']),
        departmentId: 0,
        levelId: 0,
        levelName: String(p['levelName']),
        feeFen: Number(p['feeFen']),
        visitDate: String(p['visitDate']),
        startTime: String(p['startTime']),
        endTime: String(p['endTime']),
        remainingQuota: 1
      }
    }
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
    } catch (e) { /* toast 已弹 */ }
    finally { this.paying = false }
  }

  build() {
    Column() {
      AppBar({ title:'确认预约' })
      // 医院 / 科室 / 医生信息卡
      Column() {
        Text('东软云医院').fontSize(23).fontWeight(700).alignSelf(ItemAlign.Start)
        if (this.slot) {
          Row() { AvatarIcon({name:this.slot.doctorName,iconSize:64}).margin({right:14})
            Column() {
              Text(this.slot.doctorName).fontSize(22).fontWeight(600)
              Text(`${this.slot.levelName} · ${Format.date(this.slot.visitDate)} ${Format.time(this.slot.startTime)}-${Format.time(this.slot.endTime)}`)
                .fontSize(19).fontColor($r('app.color.text_secondary')).margin({top:6})
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            FeeTag({ fen: this.slot.feeFen, type:'secondary', iconSize:'lg' })
          }.margin({top:14})
        } else { Text('加载号源信息…').fontColor($r('app.color.text_hint')).margin({top:12}) }
      }.width('92%').padding(18).margin({top:16})
       .backgroundColor($r('app.color.bg_card')).borderRadius(16)

      // 就诊人卡
      Column() {
        Text('就诊人').fontSize(24).fontWeight(700).alignSelf(ItemAlign.Start)
        if (this.contact) {
          Row() { AvatarIcon({name:this.contact.name,iconSize:52}).margin({right:14})
            Column() {
              Text(this.contact.name).fontSize(23).fontWeight(600)
              Text(`${Format.maskPhone(this.contact.phone)} · ${relationText(this.contact.relation)}`)
                .fontSize(20).fontColor($r('app.color.text_hint')).margin({top:6})
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          }.margin({top:14})
        }
      }.width('92%').padding(18).margin({top:12})
       .backgroundColor($r('app.color.bg_card')).borderRadius(16)

      Blank().layoutWeight(1)

      Row() {
        Column() {
          Text('支付金额').fontSize(22).fontColor($r('app.color.text_hint'))
          if (this.slot) { FeeTag({ fen: this.slot.feeFen, type:'danger', iconSize:'lg' }).margin({top:4}) }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        PrimaryButton({ label:'立即支付', isEnabled:!this.paying, onTap:() => this.pay() }).width(180)
      }
      .width('100%').padding(18)
      .backgroundColor($r('app.color.bg_card'))
      .borderWidth({top:0.5}).borderColor($r('app.color.divider'))
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
