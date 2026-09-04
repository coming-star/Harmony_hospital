/**
 * 【预约 Tab】预约科室选择入口。
 * 直接显示一级科室卡片列表（带描述），点击展开二级科室，再点击二级科室进入选医生/时间页。
 */
import router from '@ohos.router'
import { Route } from '../utils/theme'
import { DepartmentAccordion } from '../components/DepartmentAccordion'

@Component
export struct AppointmentTab {
  build() {
    Column() {
      DepartmentAccordion()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
