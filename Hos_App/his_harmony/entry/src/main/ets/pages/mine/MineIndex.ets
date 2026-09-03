/**
 * 【我的 子路由壳】对应 main_pages.json 中 pages/mine/MineIndex。
 * Tabs 里"我的"Tab 直接用 MineTab 渲染，本页作为独立路由入口（如退出登录后跳转、路由跳我的）。
 * 内容复用 MineTab，避免重复维护两套"我的"页面。
 */
import { MineTab } from '../MineTab'

@Entry
@Component
struct MineIndex {
  build() {
    Column() {
      MineTab()
    }
    .width('100%')
    .height('100%')
  }
}
