/**
 * Tabs 容器主页（应用冷启动进入的第一个页面，main_pages.json 第一项）。
 * 4 个底部 Tabs + 4 个子 Tab Content。
 * 每个 Tab 的具体 UI/逻辑 拆分到 HomeTab/AppointmentTab/AITab/MineTab 四个组件中。
 */
import { TAB_INDEX, TAB_KEYS, TAB_LABELS, TabKey, Theme, Route } from '../utils/theme'
import router from '@ohos.router'

// 具体 Tab 内容页（目前是骨架 UI，由对应负责人补充真实接口数据与卡片 UI）
import { HomeTab } from './HomeTab'
import { AppointmentTab } from './AppointmentTab'
import { AITab } from './AITab'
import { MineTab } from './MineTab'

@Entry
@Component
struct Index {
  @State currentIndex: number = TAB_INDEX.home
  private tabKeys: TabKey[] = [...TAB_KEYS]

  /** 根据 Tab key 拿选中色（首页/我的=主色；预约=蓝；AI=紫） */
  private activeColor(key: TabKey): ResourceColor {
    return Theme.TabActiveColor[key]
  }

  /** Tab 图标：用 emoji 占位（正式版替换为 iconfont 或 SVG/png；或直接用内置 symbolGlyph）*/
  private iconFor(key: TabKey, active: boolean): string {
    const map: Record<TabKey, [string, string]> = {
      home: ['🏠', '🏡'],
      appointment: ['📅', '🗓️'],
      ai: ['🤖', '🧠'],
      mine: ['👤', '🙂']
    }
    return map[key][active ? 1 : 0]
  }

  @Builder TabBuilder(key: TabKey, index: number) {
    Column() {
      Text(this.iconFor(key, this.currentIndex === index))
        .fontSize($r('app.float.fs_24'))
        .margin({ bottom: 2 })
      Text(TAB_LABELS[key])
        .fontSize($r('app.float.fs_12'))
        .fontColor(this.currentIndex === index ? this.activeColor(key) : $r('app.color.text_hint'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      TabContent() { HomeTab() }
        .tabBar(this.TabBuilder('home', TAB_INDEX.home))

      TabContent() { AppointmentTab() }
        .tabBar(this.TabBuilder('appointment', TAB_INDEX.appointment))

      TabContent() { AITab() }
        .tabBar(this.TabBuilder('ai', TAB_INDEX.ai))

      TabContent() { MineTab() }
        .tabBar(this.TabBuilder('mine', TAB_INDEX.mine))
    }
    .barHeight($r('app.float.tab_bar_height'))
    .barBackgroundColor($r('app.color.bg_card'))
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .onChange((idx: number) => { this.currentIndex = idx })
  }
}
