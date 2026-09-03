/**
 * 【预约 Tab 占位页】交付负责人：成员 C。
 * 路由规则：预约 Tab 直接跳 DepartmentSelect。
 * TODO 成员 C：在此页可放"最近预约记录"快捷进入（和 MineTab 复用 OrderDetail 卡片）。
 */
import router from '@ohos.router'
import { Route } from '../../utils/theme.ets'
@Entry
@Component
struct AppointmentIndex {
  aboutToAppear() {
    // Tab 首次切换到 appointment 时自动跳到科室选择页（跟小程序"预约 Tab 是第一流程页"一样）
    try { router.pushUrl({ url: Route.DEPT_SELECT }) } catch(_) {}
  }
  build() {
    Column().width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
