/**
 * 【AI 聊天子页】交付负责人：成员 D
 * 注意：AITab（Tab 第三项）已经是聊天 UI，两者可以 1:1 共享同一份组件；
 * 这个子页主要用于"从我的页或首页点 AI 入口"进入的全聊天页面。
 * TODO 成员 D：把 AITab.ets 代码复制过来（或抽公共 ChatPane 组件共用）并接入真实 /api/ai/chat。
 */
import { AITab } from '../AITab'

@Entry
@Component
struct AIChat {
  build() {
    Column() { AITab() }.width('100%').height('100%')
  }
}
