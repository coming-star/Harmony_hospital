/**
 * 【选择科室】页面（可从首页"在线挂号"快捷入口、"全部"链接进入）。
 * 顶部 AppBar + DepartmentAccordion 科室级联组件。
 */
import { AppBar } from '../../components/AppBar'
import { DepartmentAccordion } from '../../components/DepartmentAccordion'

@Entry
@Component
struct DepartmentSelect {
  build() {
    Column() {
      AppBar({ title: '选择科室' })
      DepartmentAccordion()
    }
    .width('100%')
    .height('100%')
  }
}
