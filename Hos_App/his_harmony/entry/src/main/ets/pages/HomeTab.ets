/**
 * 首页 Tab（完全匹配参考图左侧第一张）：
 *   蓝色大方块栏（东软云医院+副标+右上角听诊器图标+下方白色圆角搜索框）
 * + Swiper 医院建筑风景 Banner
 * + 4 方方图标（在线挂号📅 / 挂号记录📋 / 就诊人👨‍👩‍👧 / AI咨询🤖）
 * + 「热门科室」 标题 + "全部>" → 跳转科室选择；下方 2×2 大圆角方卡（听诊器图标+科室名+简介）
 * + 下方推荐医生占位区
 *
 * 交付负责人：成员 B
 */
import router from '@ohos.router'
import { Route } from '../utils/theme'
import { AppIcon } from '../utils/icons'
import { SquareIconCard } from '../components/SquareIconCard'
import { SectionTitle } from '../components/SectionTitle'
import { EmptyState } from '../components/EmptyState'
import { StethoscopeIcon } from '../components/StethoscopeIcon'
import type { DepartmentTreeNode, QuickEntryItem } from '../types'
import * as deptApi from '../api/department'

@Component
export struct HomeTab {
  @State departments: DepartmentTreeNode[] = []
  private readonly entries: QuickEntryItem[] = [
    { key:'book',   label:'在线挂号', iconFont: AppIcon.appointmentOutline, route: Route.DEPT_SELECT },
    { key:'orders', label:'挂号记录', iconFont: AppIcon.message, route: Route.ORDER_RECORD },
    { key:'peo',    label:'就诊人',   iconFont: AppIcon.profileOutline, route: Route.CONTACT_MGNT },
    { key:'ai',     label:'AI咨询',   iconFont: AppIcon.aiOutline,   route: Route.AI_CHAT }
  ]

  async aboutToAppear(): Promise<void> {
    try { this.departments = await deptApi.getDepartmentTree() } catch (_) {}
  }

  private getHotDepts(): DepartmentTreeNode[] {
    const arr: DepartmentTreeNode[] = []
    this.departments.forEach((l1: DepartmentTreeNode) => {
      const kids: DepartmentTreeNode[] = l1.children ?? []
      kids.forEach((l2: DepartmentTreeNode) => arr.push(l2))
    })
    return arr.slice(0, 4)
  }

  @Builder TopBlueHeader() {
    // 参考图首页蓝色顶栏（192vp 高）
    Column() {
      Row() {
        Column() {
          Text('东软云医院').fontSize(32).fontWeight(800).fontColor($r('app.color.text_white'))
          Text('预约挂号 · 健康管理').fontSize(20).fontColor('#CCFFFFFF').margin({ top: 6 })
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }.width('100%').padding({ top: 4, left: 20, right: 20, bottom: 16 })

      // 白色大圆角搜索框
      Row() {
        SymbolGlyph($r(AppIcon.search))
          .fontSize(22)
          .margin({ left: 16, right: 8 })
        Text('搜索科室、医生').fontSize(20).fontColor($r('app.color.text_hint'))
          .layoutWeight(1)
      }
      .width('92%').height(52)
      .backgroundColor(Color.White)
      .borderRadius(999)
      .margin({ bottom: 20, left: 20, right: 20 })
      .onClick(() => { try { router.pushUrl({ url: Route.DEPT_SELECT }) } catch (_) {} })
    }
    .width('100%')
    .backgroundColor($r('app.color.primary'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder Banner() {
    Swiper() {
      ForEach([1,2,3], (i: number) => {
        Stack() {
          // 参考图首页 Banner：医院建筑外景（占位图 placehold.co，可替换成真实图）
          Image($r(`app.media.banner${i}`))
            .width('100%').height(180).borderRadius(20)
            .objectFit(ImageFit.Cover)
        }
      })
    }
    .width('92%').height(180)
    .margin({ top: 16 })
    .autoPlay(true).indicator(true).itemSpace(10)
  }

  @Builder QuickEntries() {
    Row() {
      ForEach(this.entries, (it: QuickEntryItem) => {
        Column() {
          SquareIconCard({
            icon: it.iconFont,
            label: it.label,
            bg: $r('app.color.primary_light'),
            fg: $r('app.color.primary'),
            onTap: () => { try { router.pushUrl({ url: it.route }) } catch (_) {} }
          })
        }.layoutWeight(1).justifyContent(FlexAlign.Center)
      })
    }
    .width('92%').margin({ top: 20 })
  }

  @Builder HotDepts() {
    SectionTitle({
      title: '热门科室', moreText: '全部',
      onMore: () => { try { router.pushUrl({ url: Route.DEPT_SELECT }) } catch (_) {} }
    })
    if (this.getHotDepts().length === 0) {
      Column() {
        SymbolGlyph($r(AppIcon.emptyBox))
          .fontSize(56)
          .margin({ bottom: 8 })
        Text('暂无可展示科室')
          .fontSize(22)
          .fontColor($r('app.color.text_hint'))
      }
      .width('100%')
      .padding({
        top: 32,
        bottom: 20
      })
    } else {
      Grid() {
        ForEach(this.getHotDepts(), (d: DepartmentTreeNode) => {
          GridItem() {
            Column() {
              Row() {
                Stack() {
                  Circle().width(56).height(56).fill($r('app.color.primary_light'))
                  StethoscopeIcon({ customSize: 44, color: $r('app.color.primary') })
                }.margin({ right: 12 })
                Column() {
                  Text(d.name).fontSize(22).fontWeight(700).fontColor($r('app.color.text_primary'))
                  if (d.description) {
                    Text(d.description).fontSize(17).fontColor($r('app.color.text_secondary'))
                      .margin({top:6}).maxLines(3).textOverflow({overflow:TextOverflow.Ellipsis})
                  }
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                SymbolGlyph($r(AppIcon.forward))
                  .fontSize(24)
                  .margin({right:4})
              }
              .width('100%').padding(18)
            }
            .width('100%').height(132)
            .backgroundColor($r('app.color.bg_card'))
            .borderRadius($r('app.float.radius_md'))
            .onClick(() => {
              router.pushUrl({ url: Route.DOCTOR_LIST, params: { departmentId: d.id } })
            })
          }
        }, (d: DepartmentTreeNode) => String(d.id))
      }
      .columnsTemplate('1fr 1fr').rowsGap(12).columnsGap(12)
      .width('100%').padding({ left: 20, right: 20, top: 8, bottom: 16 })
      .backgroundColor(Color.Transparent)
    }
  }

  build() {
    Scroll() {
      Column() {
        this.TopBlueHeader()
        this.Banner()
        this.QuickEntries()
        this.HotDepts()
        Blank().height(40)
      }.width('100%')
    }
    .width('100%').height('100%').scrollBar(BarState.Off).backgroundColor($r('app.color.bg_page'))
  }
}
