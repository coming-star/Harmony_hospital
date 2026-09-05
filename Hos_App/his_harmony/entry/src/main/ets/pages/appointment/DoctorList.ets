/**
 * 【医生列表 + 时段选择】交付负责人：成员 C
 * 接收 router 参数：departmentId （必填），visitDate（可选，默认今天）
 * 风格：顶部 AppBar 蓝色「选择医生」；下方 7 天切换横条改成参考图"圆角胶囊选中态=主色蓝"；时段按钮灰底不可点 / 蓝底主色可点。
 */
import router from '@ohos.router'
import type { SlotSummary } from '../../types'
import { Format } from '../../utils/format'
import type { DayItem } from '../../utils/format'
import { Route } from '../../utils/theme'
import { AppBar } from '../../components/AppBar'
import * as slotApi from '../../api/slot'
import { FeeTag } from '../../components/FeeTag'
import { AvatarIcon } from '../../components/AvatarIcon'
import { promptAction } from '@kit.ArkUI'

interface DoctorDayView { date: string; mmdd: string; weekday: string; isToday: boolean }

interface LevelTab { levelId: number; label: string }
const LEVEL_TABS: LevelTab[] = [
  { levelId: 0,    label: '全部' },
  { levelId: 3001, label: '普通号' },
  { levelId: 3002, label: '专家号' },
  { levelId: 3003, label: '主任医师号' },
]

interface DoctorGroup {
  doctorId: number
  doctorName: string
  items: SlotSummary[]
}

@Entry
@Component
struct DoctorList {
  @State departmentId: number = 0
  @State visitDate: string = Format.next7Days(0)[0].iso
  @State days: DoctorDayView[] = Format.next7Days(0).map((d: DayItem): DoctorDayView => {
    return { date: d.iso, mmdd: d.mmdd, weekday: d.weekday, isToday: d.isToday }
  })
  @State slots: SlotSummary[] = []
  @State selectedLevelId: number = 0

  async aboutToAppear(): Promise<void> {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined
    if (params && params['departmentId']) {
      this.departmentId = Number(params['departmentId'])
      await this.loadSlots()
    }
  }
  async loadSlots(): Promise<void> {
    if (!this.departmentId) return
    try { this.slots = await slotApi.listSlots({ departmentId: this.departmentId, date: this.visitDate }) }
    catch (_) {}
  }
  private doctors(): DoctorGroup[] {
    const filtered = this.selectedLevelId === 0
      ? this.slots
      : this.slots.filter((s: SlotSummary) => s.levelId === this.selectedLevelId)
    const m: Map<number, DoctorGroup> = new Map<number, DoctorGroup>()
    filtered.forEach((s: SlotSummary) => {
      let g: DoctorGroup | undefined = m.get(s.doctorId)
      if (!g) { g = { doctorId: s.doctorId, doctorName: s.doctorName, items: [] }; m.set(s.doctorId, g) }
      g.items.push(s)
    })
    return Array.from(m.values())
  }
  private pickSlot(s: SlotSummary): void {
    if (s.remainingQuota <= 0) { promptAction.showToast({ message:'该时段已约满' }); return }
    router.pushUrl({ url: Route.CONTACT_SELECT, params: {
      slotId: s.slotId,
      doctorName: s.doctorName,
      levelName: s.levelName,
      feeFen: s.feeFen,
      visitDate: s.visitDate,
      startTime: s.startTime,
      endTime: s.endTime
    } })
  }

  build() {
    Column() {
      AppBar({ title:'选择医生' })
      // 顶部 7 天切换条（参考图：选中态蓝底白字）
      Scroll() {
        Row() {
          ForEach(this.days, (d: DoctorDayView) => {
            Column() {
              Text(d.isToday ? '今天' : d.weekday)
                .fontSize(17)
                .fontColor(d.date === this.visitDate ? $r('app.color.text_white') : $r('app.color.text_secondary'))
              Text(d.mmdd)
                .fontSize(20).fontWeight(d.date === this.visitDate ? 700 : 500)
                .fontColor(d.date === this.visitDate ? $r('app.color.text_white') : $r('app.color.text_primary'))
                .margin({ top: 4 })
            }
            .width(72).height(74).justifyContent(FlexAlign.Center)
            .borderRadius($r('app.float.radius_md'))
            .backgroundColor(d.date === this.visitDate ? $r('app.color.primary') : $r('app.color.bg_card'))
            .margin({ right: 10 })
            .shadow({ radius: d.date === this.visitDate ? 0 : 1, color: '#11000000', offsetY: 1 })
            .onClick(() => { this.visitDate = d.date; this.loadSlots() })
          })
        }.padding(16)
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')

      // 挂号级别筛选 Tab：全部 / 普通号 / 专家号 / 主任医师号
      Scroll() {
        Row() {
          ForEach(LEVEL_TABS, (t: LevelTab) => {
            Text(t.label)
              .fontSize(18)
              .fontWeight(this.selectedLevelId === t.levelId ? 600 : 400)
              .fontColor(this.selectedLevelId === t.levelId ? $r('app.color.text_white') : $r('app.color.text_secondary'))
              .padding({ left: 16, right: 16, top: 10, bottom: 10 })
              .borderRadius(20)
              .backgroundColor(this.selectedLevelId === t.levelId ? $r('app.color.primary') : $r('app.color.bg_card'))
              .margin({ right: 10 })
              .onClick(() => { this.selectedLevelId = t.levelId })
          }, (t: LevelTab) => String(t.levelId))
        }.padding({ left: 16, right: 16 })
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
      .margin({ bottom: 4 })

      if (this.doctors().length === 0) {
        Column() { Text('当日暂无号源')
            .fontSize(20).fontColor($r('app.color.text_hint'))
            .padding({top:40}) }.layoutWeight(1)
      } else {
        List() {
          ForEach(this.doctors(), (g: DoctorGroup) => {
            ListItem() {
              Column() {
                Row() {
                  AvatarIcon({ name: g.doctorName, iconSize: 56 })
                  Column() {
                    Text(g.doctorName).fontSize(21).fontWeight(700)
                      .fontColor($r('app.color.text_primary'))
                    // TODO 成员 C：拿职称/简介（这里可以调医生详情接口单独加）
                  }.margin({ left: 14 }).layoutWeight(1).alignItems(HorizontalAlign.Start)
                }.padding(18)

                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                  ForEach(g.items, (s: SlotSummary) => {
                    Column() {
                      Text(`${Format.time(s.startTime)}-${Format.time(s.endTime)}`)
                        .fontSize(21)
                        .fontColor(s.remainingQuota <= 0 ? $r('app.color.disabled') : $r('app.color.text_primary'))
                      Row() {
                        FeeTag({ fen: s.feeFen, iconSize: 'sm' })
                        Text(`余${s.remainingQuota}`)
                          .fontSize(19).fontColor(s.remainingQuota <= 0 ? $r('app.color.disabled') : $r('app.color.text_hint'))
                          .margin({ left: 8 })
                      }.margin({ top: 6 })
                    }
                    .width('45%').padding(12).margin(6)
                    .justifyContent(FlexAlign.Center)
                    .borderRadius($r('app.float.radius_md'))
                    .borderWidth(1)
                    .borderColor(s.remainingQuota <= 0 ? $r('app.color.disabled_light') : $r('app.color.primary'))
                    .backgroundColor(s.remainingQuota <= 0 ? $r('app.color.disabled_light') : $r('app.color.bg_card'))
                    .onClick(() => this.pickSlot(s))
                  }, (s: SlotSummary) => String(s.slotId))
                }.padding({ left: 18, right: 18, bottom: 18 })
              }
              .width('92%').margin({ top: 14, bottom: 4 }).alignSelf(ItemAlign.Center)
              .backgroundColor($r('app.color.bg_card'))
              .borderRadius($r('app.float.radius_lg'))
            }.width('100%')
          }, (g: DoctorGroup) => String(g.doctorId))
        }.layoutWeight(1).width('100%')
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
