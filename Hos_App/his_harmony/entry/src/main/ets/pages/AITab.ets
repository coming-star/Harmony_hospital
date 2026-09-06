/**
 * 【AI Tab】AI 健康管家对话页（已接入后端 /api/ai/chat 落库多会话）。
 * - 顶部蓝色 AppBar（右侧"历史会话"入口 → bindSheet 抽屉：会话列表 / 新建 / 删除 / 切换）
 * - 气泡对话（左侧 AI 蓝灰气泡可带号源卡片 / 右侧用户品牌蓝气泡）
 * - 首条对话由服务端自动建会话并返回 conversationId；切换会话时服务端加载历史（含号源卡片还原）
 * - 底部输入栏（灰底圆角输入框 + 蓝色圆角发送按钮）
 */
import { AppBar } from '../components/AppBar'
import { AppIcon } from '../utils/icons'
import { Format } from '../utils/format'
import { FeeTag } from '../components/FeeTag'
import { Route } from '../utils/theme'
import * as aiApi from '../api/ai'
import type { ConversationItem, AiHistoryMessage } from '../api/ai'
import type { SlotSummary } from '../types'
import router from '@ohos.router'
import { inputMethod } from '@kit.IMEKit'

interface Msg { id: string; role: 'user'|'ai'; content: string; slots?: SlotSummary[] }

const WELCOME: string = '你好！我是 AI 健康管家，可以为你解答健康问题、查询科室医生、协助预约挂号。'

@Component
export struct AITab {
  @State list: Msg[] = [
    { id: Format.uuid(), role:'ai', content: WELCOME }
  ]
  @State input: string = ''
  /** 当前会话 ID（''= 尚未建会话，首条消息发送后由服务端创建并回传） */
  @State currentConversationId: string = ''
  @State drawerShow: boolean = false
  @State conversations: ConversationItem[] = []
  private scroller: Scroller = new Scroller()

  private async send(): Promise<void> {
    const text: string = this.input.trim()
    if (!text) return
    this.input = ''
    const userMsg: Msg = { id: Format.uuid(), role: 'user', content: text }
    this.list.push(userMsg)
    this.scroller.scrollEdge(Edge.Bottom)

    try {
      // 只传本次消息 + 会话 ID；历史上下文由服务端加载
      const body: aiApi.AiChatIn = {
        conversationId: this.currentConversationId === '' ? undefined : this.currentConversationId,
        content: text
      }
      const out = await aiApi.aiChat(body)
      if (out.conversationId) {
        this.currentConversationId = out.conversationId
      }
      const aiMsg: Msg = { id: Format.uuid(), role: 'ai', content: out.reply, slots: out.slots }
      this.list.push(aiMsg)
    } catch (_) {
      // request.ets 已统一 toast；这里补一条降级提示，避免界面无反馈
      const failMsg: Msg = { id: Format.uuid(), role: 'ai', content: '抱歉，AI 服务暂时不可用，请稍后再试。' }
      this.list.push(failMsg)
    }
    this.scroller.scrollEdge(Edge.Bottom)
  }

  /* ==================== 会话抽屉 ==================== */

  private async openDrawer(): Promise<void> {
    this.drawerShow = true
    try {
      this.conversations = await aiApi.listConversations()
    } catch (_) { /* request.ets 已统一 toast */ }
  }

  /** 新建对话：清空当前会话状态（服务端在发送首条消息时才真正建会话） */
  private startNewConversation(): void {
    this.resetToWelcome()
    this.drawerShow = false
  }

  private resetToWelcome(): void {
    this.currentConversationId = ''
    const welcome: Msg = { id: Format.uuid(), role: 'ai', content: WELCOME }
    this.list = [welcome]
  }

  private async selectConversation(id: string): Promise<void> {
    try {
      const msgs: AiHistoryMessage[] = await aiApi.conversationMessages(id)
      this.currentConversationId = id
      const history: Msg[] = [{ id: Format.uuid(), role: 'ai', content: WELCOME }]
      for (const m of msgs) {
        const item: Msg = {
          id: m.id,
          role: m.role === 'ASSISTANT' ? 'ai' : 'user',
          content: m.content,
          slots: m.slots === undefined ? undefined : m.slots
        }
        history.push(item)
      }
      this.list = history
      this.drawerShow = false
      this.scroller.scrollEdge(Edge.Bottom)
    } catch (_) { /* request.ets 已统一 toast */ }
  }

  private async removeConversation(id: string): Promise<void> {
    try {
      await aiApi.deleteConversation(id)
      this.conversations = this.conversations.filter((c: ConversationItem) => c.id !== id)
      if (this.currentConversationId === id) {
        this.resetToWelcome()
      }
    } catch (_) { /* request.ets 已统一 toast */ }
  }

  /** "2026-09-06 14:30:00" → "09-06 14:30" */
  private fmtConvTime(lastMessageAt: string): string {
    if (lastMessageAt && lastMessageAt.length >= 16) {
      return lastMessageAt.substring(5, 16)
    }
    return lastMessageAt
  }

  @Builder convDrawer() {
    Column() {
      Row() {
        Text('历史会话').fontSize(22).fontWeight(700).layoutWeight(1)
        Text('+ 新对话')
          .fontSize(18).fontColor($r('app.color.text_blue'))
          .padding(8)
          .onClick(() => this.startNewConversation())
      }
      .width('92%').margin({ top: 16 })

      if (this.conversations.length === 0) {
        Column() {
          Text('暂无历史会话').fontSize(18).fontColor($r('app.color.text_hint'))
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.conversations, (c: ConversationItem) => {
            ListItem() {
              Row() {
                Column() {
                  Text(c.title)
                    .fontSize(19).fontColor($r('app.color.text_primary'))
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  if (c.lastMessageAt) {
                    Text(this.fmtConvTime(c.lastMessageAt))
                      .fontSize(14).fontColor($r('app.color.text_hint')).margin({ top: 4 })
                  }
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)

                SymbolGlyph($r(AppIcon.delete))
                  .fontSize(22)
                  .fontColor([$r('app.color.text_hint')])
                  .margin({ left: 12 })
                  .onClick(() => this.removeConversation(c.id))
              }
              .width('92%').padding(14)
              .backgroundColor(c.id === this.currentConversationId
                ? $r('app.color.primary_light') : $r('app.color.bg_card'))
              .borderRadius($r('app.float.radius_md'))
              .margin({ top: 8 })
              .onClick(() => this.selectConversation(c.id))
            }.width('100%')
          }, (c: ConversationItem) => c.id)
        }
        .width('100%').layoutWeight(1).margin({ top: 8 }).scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.sheet_bg'))
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
      AppBar({ title: 'AI健康管家', hideBack: true, rightIcon: AppIcon.history, onRightClick: (): void => { this.openDrawer() } })

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
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
    // 历史会话抽屉（底部弹出）
    .bindSheet($$this.drawerShow, this.convDrawer(), {
      height: 600,
      preferType: SheetType.BOTTOM,
      showClose: true,
      dragBar: true,
      backgroundColor: $r('app.color.sheet_bg')
    })
  }
}
