/**
 * 【AI Tab】AI 健康管家对话页（已接入后端 /api/ai/chat，DeepSeek 多轮对话 + 号源卡片）。
 * 顶部蓝色 AppBar（"AI健康管家"）
 * + 气泡对话（左侧 AI 蓝灰气泡 / 右侧用户 品牌蓝 气泡；AI 气泡可带号源卡片）
 * + 底部输入栏（灰底圆角输入框"输入你的问题…"+ 蓝色圆角发送按钮）
 */
import { AppBar } from '../components/AppBar'
import { AppIcon } from '../utils/icons'
import { Format } from '../utils/format'
import { FeeTag } from '../components/FeeTag'
import { Route } from '../utils/theme'
import * as aiApi from '../api/ai'
import type { ChatMessageItem } from '../api/ai'
import type { SlotSummary } from '../types'
import router from '@ohos.router'
import { inputMethod } from '@kit.IMEKit'

interface Msg { id: string; role: 'user'|'ai'; content: string; slots?: SlotSummary[] }

@Component
export struct AITab {
  @State list: Msg[] = [
    { id: Format.uuid(), role:'ai', content:'你好！我是 AI 健康管家，可以为你解答健康问题、查询科室医生、协助预约挂号。'}
  ]
  @State input: string = ''
  private scroller: Scroller = new Scroller()

  private async send(): Promise<void> {
    const text: string = this.input.trim()
    if (!text) return
    this.input = ''
    this.list.push({ id: Format.uuid(), role: 'user', content: text })
    this.scroller.scrollEdge(Edge.Bottom)

    try {
      // 组多轮消息（跳过首条欢迎语），带上下文发给后端
      const messages: ChatMessageItem[] = []
      for (let i: number = 1; i < this.list.length; i++) {
        const m: Msg = this.list[i]
        messages.push({ role: m.role === 'ai' ? 'assistant' : 'user', content: m.content })
      }
      const out = await aiApi.aiChat({ messages })
      this.list.push({ id: Format.uuid(), role: 'ai', content: out.reply, slots: out.slots })
    } catch (_) {
      // request.ets 已统一 toast；这里补一条降级提示，避免界面无反馈
      this.list.push({ id: Format.uuid(), role: 'ai', content: '抱歉，AI 服务暂时不可用，请稍后再试。' })
    }
    this.scroller.scrollEdge(Edge.Bottom)
  }

  /** 号源卡片：点击跳就诊人选择，复用现有预约流程 */
  @Builder SlotCard(s: SlotSummary) {
    Row() {
      Column() {
        Text(s.doctorName).fontSize(20).fontWeight(600).fontColor($r('app.color.text_primary'))
        Text(`${s.levelName} · ${s.visitDate} ${Format.time(s.startTime)}-${Format.time(s.endTime)}`)
          .fontSize(16).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Column() {
        FeeTag({ fen: s.feeFen, iconSize: 'sm' })
        Text(`余${s.remainingQuota}`).fontSize(15).fontColor($r('app.color.text_hint')).margin({ top: 4 })
      }.alignItems(HorizontalAlign.End)
    }
    .width('100%').padding(12)
    .backgroundColor($r('app.color.primary_light'))
    .borderRadius($r('app.float.radius_md'))
    .margin({ top: 8 })
    .onClick(() => {
      router.pushUrl({ url: Route.CONTACT_SELECT, params: {
        slotId: s.slotId,
        doctorName: s.doctorName,
        levelName: s.levelName,
        feeFen: s.feeFen,
        visitDate: s.visitDate,
        startTime: s.startTime,
        endTime: s.endTime
      } })
    })
  }

  @Builder Bubble(m: Msg) {
    Row() {
      if (m.role === 'ai') {
        Column() {
          Text(m.content)
            .fontSize(24).fontColor($r('app.color.text_primary'))
            .padding(14).maxLines(999)
          if (m.slots && m.slots.length > 0) {
            ForEach(m.slots, (s: SlotSummary) => {
              this.SlotCard(s)
            }, (s: SlotSummary) => String(s.slotId))
          }
        }
        .backgroundColor($r('app.color.bg_card'))
        .borderRadius($r('app.float.radius_md'))
        .margin({ right: 64 })
        .layoutWeight(1)
      } else {
        Blank()
        Column() { Text(m.content)
            .fontSize(22).fontColor($r('app.color.text_white'))
            .padding(14).maxLines(999) }
          .backgroundColor($r('app.color.primary'))
          .borderRadius($r('app.float.radius_md'))
          .margin({ left: 64 })
          .layoutWeight(1)
      }
    }
    .width('100%').margin({bottom:12})
    .padding({ left: 16, right: 16 })
  }

  build() {
    Column() {
      AppBar({ title: 'AI健康管家', hideBack: true })

      List({ space:0, scroller: this.scroller }) {
        ForEach(this.list, (m: Msg) => {
          ListItem() { this.Bubble(m) }.width('100%')
        }, (m: Msg) => m.id)
      }.layoutWeight(1).padding({top:8,bottom:8}).scrollBar(BarState.Off)
       // 对话区豁免键盘避让：键盘弹出时只有输入栏上移，列表不再被整体顶上去
       .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.BOTTOM])
       // 点击对话空白区收起软键盘
       .onClick(() => { inputMethod.getController().hideTextInput() })

      // 底部输入栏（参考图同款：灰输入框 + 蓝圆角发送按钮）
      Row() {
        TextInput({ placeholder:'输入你的问题...', text: this.input })
          .layoutWeight(1).height(60)
          .backgroundColor($r('app.color.input_bg'))
          .borderRadius($r('app.float.radius_md'))
          .padding({left:16,right:16})
          .fontSize(30)
          .placeholderColor($r('app.color.text_hint'))
          .onChange(v => this.input = v)
          .onSubmit(() => { this.send() })

        Stack({alignContent:Alignment.Center}) {
          Column().width(52).height(52).borderRadius(14).backgroundColor($r('app.color.primary'))
          SymbolGlyph($r(AppIcon.send))
            .fontSize(24)
        }
        .margin({left:12})
        .onClick(() => { this.send() })
      }.width('100%').padding(12).backgroundColor($r('app.color.bg_card'))
       .borderWidth({top:0.5}).borderColor($r('app.color.divider'))
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
