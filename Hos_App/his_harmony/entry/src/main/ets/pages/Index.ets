/**
 * Tabs 容器主页（应用冷启动进入的第一个页面，main_pages.json 第一项）。
 * 4 个底部 Tabs + 4 个子 Tab Content。
 * 每个 Tab 的具体 UI/逻辑 拆分到 HomeTab/AppointmentTab/AITab/MineTab 四个组件中。
 */
import { TAB_INDEX, TAB_KEYS, TAB_LABELS, TabKey, Theme, Route } from '../utils/theme'
import { AppIcon } from '../utils/icons'
import router from '@ohos.router'

// 具体 Tab 内容页（目前是骨架 UI，由对应负责人补充真实接口数据与卡片 UI）
import { HomeTab } from './HomeTab'
import { AppointmentTab } from './AppointmentTab'
import { AITab } from './AITab'
import { MineTab } from './MineTab'

interface TabIconMap {
  home: string[]
  appointment: string[]
  ai: string[]
  mine: string[]
}

@Entry
@Component
struct Index {
  @State currentIndex: number = TAB_INDEX.home
  private tabKeys: TabKey[] = [...TAB_KEYS]

  private activeColor(key: TabKey): ResourceColor {
    return $r('app.color.primary')
  }

  private labelFor(key: TabKey): string {
    switch (key) {
      case 'home': return '首页'
      case 'appointment': return '预约'
      case 'ai': return 'AI管家'
      case 'mine': return '我的'
      default: return ''
    }
  }

  private iconFor(key: TabKey): string {
    switch (key) {
      case 'home': return AppIcon.homeOutline
      case 'appointment': return AppIcon.appointmentOutline
      case 'ai': return AppIcon.aiOutline
      case 'mine': return AppIcon.profileOutline
      default: return AppIcon.homeOutline
    }
  }

  @Builder TabBuilder(key: TabKey, index: number) {
    Column() {
      SymbolGlyph($r(this.iconFor(key)))
        .fontSize(34)
        .margin({ top: 8, bottom: 8 })
      Text(this.labelFor(key))
        .fontSize(20)
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
