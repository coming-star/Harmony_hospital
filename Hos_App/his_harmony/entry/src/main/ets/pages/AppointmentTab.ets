/**
 * 【预约 Tab】骨架占位（交付负责人：成员 C）。
 * 注意：完整预约流程的"科室→医生→时段→就诊人→确认→成功"放在 pages/appointment/* 五个子页面里。
 * 本页作为 Tab 入口，通常直接跳转到「科室选择」子页，或做成"我要点预约"大卡片引导页。
 * TODO 成员 C：
 *   1. 显示"预约流程简介"的引导卡片 + 一个大号 CTA 按钮「立即预约」→ 跳 DepartmentSelect
 *   2. 可选：历史最近预约小卡片（最近一条订单的快捷入口"继续预约同款医生"）
 */
import router from '@ohos.router'
import { Route } from '../utils/theme.ets'

@Component
export struct AppointmentTab {
  build() {
    Column() {
      Column() {
        Text('预约流程').fontSize($r('app.float.fs_24')).fontWeight(FontWeight.Bold)
          .margin({ bottom: $r('app.float.sp_12') })
        Text('选科室 → 选医生 → 选时段 → 选就诊人 → 确认支付 → 预约成功')
          .fontSize($r('app.float.fs_14'))
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .margin({ bottom: $r('app.float.sp_32') })

        Button('立即预约', ButtonType.Capsule)
          .width(220)
          .height($r('app.float.btn_height_lg'))
          .backgroundColor($r('app.color.secondary_booking'))
          .fontColor($r('app.color.text_white'))
          .fontSize($r('app.float.fs_18'))
          .onClick(() => {
            router.pushUrl({ url: Route.DEPT_SELECT })
          })
      }
      .width('90%')
      .margin({ top: 120 })
      .padding($r('app.float.sp_24'))
      .backgroundColor($r('app.color.bg_card'))
      .borderRadius($r('app.float.radius_lg'))
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .shadow({ radius: $r('app.float.shadow_card'), color: '#1A000000', offsetY: 2 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.bg_page'))
  }
}
