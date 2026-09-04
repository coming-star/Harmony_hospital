/**
 * 【挂号记录】交付负责人：成员 D。
 * 顶部 4 Tab（全部/待支付/已支付/已取消）；列表卡片 + 详情展开 + "立即支付/取消预约"按钮
 */
import router from '@ohos.router'
import { Format } from '../../utils/format'
import { OrderStatusValue, OrderStatusText } from '../../types'
import { Route } from '../../utils/theme'
import { AppIcon } from '../../utils/icons'
import { AppBar } from '../../components/AppBar'
import type { OrderDetail, PageResult } from '../../types'
import * as orderApi from '../../api/order'
import type { OrderListQuery } from '../../api/order'
import { StatusTag } from '../../components/StatusTag'
import { FeeTag } from '../../components/FeeTag'
import { EmptyState } from '../../components/EmptyState'
import { ConfirmDialog } from '../../components/ConfirmDialog'
import { promptAction } from '@kit.ArkUI'

interface TabItem {
  key: string
  label: string
}

const TABS: TabItem[] = [
  { key: '',             label: '全部' },
  { key: OrderStatusValue.PENDING_PAYMENT, label: '待支付' },
  { key: OrderStatusValue.PAID,            label: '已支付' },
  { key: OrderStatusValue.CANCELLED,       label: '已取消' }
]

@Entry
@Component
struct OrderRecord {
  @State tabKey: string = ''
  @State page: number = 1
  @State pageSize: number = 20
  @State list: OrderDetail[] = []
  @State total: number = 0
  @State expandId: number = 0
  @State cancelShow: boolean = false
  @State cancelTarget: OrderDetail | undefined = undefined
  @State cancelLoading: boolean = false

  aboutToAppear(): void {
    // 可选：router params 带 tab
    const p: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined
    if (p && p['tab']) this.tabKey = String(p['tab'])
    this.reload()
  }
  onChangeTab(k: string): void { this.tabKey = k; this.page = 1; this.reload() }

  async reload(): Promise<void> {
    try {
      const q: OrderListQuery = { page: this.page, size: this.pageSize }
      if (this.tabKey) q.status = this.tabKey
      const r: PageResult<OrderDetail> = await orderApi.listMyOrders(q)
      this.list = this.page === 1 ? [...(r.records ?? [])] : [...this.list, ...(r.records ?? [])]
      this.total = r.total
    } catch (_) {}
  }

  async pay(o: OrderDetail): Promise<void> {
    try {
      await orderApi.payOrder(o.id)
      promptAction.showToast({ message:'支付成功' })
      await this.reload()
    } catch (_) {}
  }
  askCancel(o: OrderDetail): void { this.cancelTarget = o; this.cancelShow = true }
  async confirmCancel(): Promise<void> {
    if (!this.cancelTarget || this.cancelLoading) return
    this.cancelLoading = true
    try {
      await orderApi.cancelOrder(this.cancelTarget.id)
      promptAction.showToast({ message:'已取消' })
      this.cancelShow = false
      await this.reload()
    } catch (_) {}
    finally { this.cancelLoading = false }
  }

  @Builder cancelDialog() {
    ConfirmDialog({
      title: '取消预约',
      message: this.cancelTarget ? `确定要取消「${this.cancelTarget.departmentName}」的预约吗？` : '确定要取消该预约吗？',
      danger: true,
      confirmText: '确定取消',
      onConfirm: () => this.confirmCancel(),
      onCancel: () => { this.cancelShow = false }
    })
  }

  build() {
    Column() {
      AppBar({ title:'挂号记录' })
      // Tabs
      Scroll() {
        Row() {
          ForEach(TABS, (t: TabItem) => {
            Text(t.label).fontSize(14).fontWeight(this.tabKey===t.key ? 700 : 500)
              .fontColor(this.tabKey===t.key ? $r('app.color.primary') : $r('app.color.text_secondary'))
              .padding({left:16,right:16,top:12,bottom:12})
              .borderWidth({bottom: this.tabKey===t.key ? 3 : 0})
              .borderColor($r('app.color.primary'))
              .margin({right:4})
              .onClick(() => this.onChangeTab(t.key))
          })
        }.padding({left:12,right:12})
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)

      List() {
        if (this.list.length === 0) {
          ListItem() {
            Column() {
              EmptyState({
                hint: '还没有挂号记录', icon: AppIcon.message,
                actionText: '去预约', routeTo: Route.APPOINTMENT
              })
            }.width('100%')
          }.width('100%').margin({top:40})
        }
        ForEach(this.list, (o: OrderDetail) => {
          ListItem() {
            Column() {
              // 头：科室 + StatusTag
              Row() {
                Column() {
                  Text(o.departmentName).fontSize(16).fontWeight(700).fontColor($r('app.color.text_primary'))
                  Text(`${o.doctorName} · ${o.levelName}`).fontSize(12).fontColor($r('app.color.text_hint')).margin({top:4})
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                StatusTag({ status: o.status })
              }.width('100%')

              Row() { Text(`${Format.date(o.visitDate)}  ${Format.time(o.startTime)}-${Format.time(o.endTime)}`)
                  .fontSize(13).fontColor($r('app.color.text_secondary')) }.margin({top:8})

              // 详情展开
              if (this.expandId === o.id) {
                Column() {
                  this.R(`订单号`, o.orderNo)
                  this.R(`就诊人`, `${o.contactName} ${Format.maskPhone(o.contactPhone)}`)
                  this.R(`费用`, Format.yuan(o.amountFen))
                  if (o.paidAt)    this.R(`支付时间`, Format.datetime(o.paidAt))
                  if (o.cancelledAt) this.R(`取消时间`, Format.datetime(o.cancelledAt))
                }.width('100%').padding(12)
                 .backgroundColor($r('app.color.bg_page')).borderRadius(12).margin({top:12})
              }

              Row() {
                Text(this.expandId===o.id ? '收起详情' : '查看详情')
                  .fontSize(13).fontColor($r('app.color.text_hint'))
                  .padding(8).layoutWeight(1)
                  .onClick(() => { this.expandId = this.expandId===o.id ? 0 : o.id })
                // 待支付 → 立即支付
                if (o.status === OrderStatusValue.PENDING_PAYMENT) {
                  Button('取消预约').height(36).backgroundColor($r('app.color.disabled_light'))
                    .fontColor($r('app.color.text_secondary')).fontSize(13)
                    .borderRadius(999).margin({right:8})
                    .onClick(() => this.askCancel(o))
                  Button('立即支付').height(36)
                    .backgroundColor($r('app.color.warning')).fontColor(Color.White).fontSize(13)
                    .borderRadius(999)
                    .onClick(() => this.pay(o))
                }
                // 已支付 → 取消预约
                if (o.status === OrderStatusValue.PAID) {
                  Button('取消预约').height(36).backgroundColor($r('app.color.danger_light'))
                    .fontColor($r('app.color.danger')).fontSize(13).borderRadius(999)
                    .onClick(() => this.askCancel(o))
                }
              }.margin({top:12})
            }
            .width('92%').padding(16).alignSelf(ItemAlign.Center)
            .backgroundColor($r('app.color.bg_card')).borderRadius(16).margin({top:12})
          }
          .width('100%')
        }, (o: OrderDetail) => String(o.id))

        if (this.list.length > 0 && this.list.length < this.total) {
          ListItem() {
            Text('加载更多').fontSize(13).fontColor($r('app.color.text_hint'))
              .padding(16).onClick(() => { this.page += 1; this.reload() })
          }.width('100%').alignSelf(ItemAlign.Center)
        }
      }.layoutWeight(1).width('100%')
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
    .bindSheet($$this.cancelShow, this.cancelDialog(), { height: 280, preferType: SheetType.CENTER, showClose: false, dragBar: true })
  }

  @Builder R(k: string, v: string) {
    Row() {
      Text(k).layoutWeight(1).fontSize(12).fontColor($r('app.color.text_hint'))
      Text(v).fontSize(13).fontColor($r('app.color.text_primary'))
    }.margin({top:6})
  }
}
