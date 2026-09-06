/**
 * 【消息中心】站内信列表页（pages/mine/MessageList）。
 * - 顶部蓝色 AppBar；其下右侧"全部已读"文字按钮
 * - 消息项：类型图标（预约成功绿/取消红/超时橙/提醒蓝）+ 标题 + 未读红点 + 两行正文 + 时间
 * - 分页加载：滚到底部自动追加下一页；点击单条标记已读并刷新全局未读数（Tab 红点）
 */
import { AppBar } from '../../components/AppBar'
import { AppIcon } from '../../utils/icons'
import { showToast } from '../../utils/toast'
import * as messageApi from '../../api/message'
import type { MessageItem, MessageType, PageResult } from '../../types'

/** 消息类型 → 图标/配色 */
interface MsgStyle {
  icon: string
  color: ResourceColor
  bg: ResourceColor
}

@Entry
@Component
struct MessageList {
  @State list: MessageItem[] = []
  @State page: number = 1
  @State loading: boolean = false
  @State hasMore: boolean = true
  private readonly pageSize: number = 10

  aboutToAppear(): void {
    this.reload()
  }

  private styleOf(type: MessageType | string): MsgStyle {
    switch (type) {
      case 'ORDER_PAY_SUCCESS':
        return { icon: AppIcon.success, color: $r('app.color.success'), bg: $r('app.color.success_light') }
      case 'ORDER_CANCELLED':
        return { icon: AppIcon.cancel, color: $r('app.color.danger'), bg: $r('app.color.danger_light') }
      case 'ORDER_TIMEOUT':
        return { icon: AppIcon.clock, color: $r('app.color.warning'), bg: $r('app.color.warning_light') }
      case 'PAYMENT_REMINDER':
        return { icon: AppIcon.clock, color: $r('app.color.warning'), bg: $r('app.color.warning_light') }
      default:
        return { icon: AppIcon.bell, color: $r('app.color.primary'), bg: $r('app.color.primary_light') }
    }
  }

  /** "2026-09-06 14:30:00" → "09-06 14:30" */
  private fmtTime(createdAt: string): string {
    if (createdAt && createdAt.length >= 16) {
      return createdAt.substring(5, 16)
    }
    return createdAt
  }

  private async reload(): Promise<void> {
    if (this.loading) return
    this.loading = true
    try {
      const out: PageResult<MessageItem> = await messageApi.listMessages(1, this.pageSize)
      this.list = out.records
      this.page = 1
      this.hasMore = this.list.length < out.total
    } catch (_) {
      // request.ets 已统一 toast
    } finally {
      this.loading = false
    }
  }

  private async loadMore(): Promise<void> {
    if (this.loading || !this.hasMore) return
    this.loading = true
    try {
      const next: number = this.page + 1
      const out: PageResult<MessageItem> = await messageApi.listMessages(next, this.pageSize)
      const known: Set<string> = new Set<string>()
      for (const m of this.list) known.add(m.id)
      const merged: MessageItem[] = this.list.concat(out.records.filter((m: MessageItem) => !known.has(m.id)))
      this.list = merged
      this.page = next
      this.hasMore = this.list.length < out.total
    } catch (_) {
      // request.ets 已统一 toast
    } finally {
      this.loading = false
    }
  }

  /** 本地重建数组标记已读（保证 @State 触发刷新） */
  private markLocalRead(id: string): void {
    const updated: MessageItem[] = this.list.map((m: MessageItem): MessageItem => {
      if (m.id === id) {
        const copy: MessageItem = { id: m.id, type: m.type, title: m.title, content: m.content, bizId: m.bizId, isRead: 1, createdAt: m.createdAt }
        return copy
      }
      return m
    })
    this.list = updated
  }

  private async tapItem(m: MessageItem): Promise<void> {
    if (m.isRead === 0) {
      try {
        await messageApi.markMessageRead(m.id)
        this.markLocalRead(m.id)
        await messageApi.refreshUnreadBadge()
      } catch (_) { /* request.ets 已统一 toast */ }
    }
  }

  private async readAll(): Promise<void> {
    if (this.loading) return
    try {
      await messageApi.markAllMessagesRead()
      const updated: MessageItem[] = this.list.map((m: MessageItem): MessageItem => {
        const copy: MessageItem = { id: m.id, type: m.type, title: m.title, content: m.content, bizId: m.bizId, isRead: 1, createdAt: m.createdAt }
        return copy
      })
      this.list = updated
      await messageApi.refreshUnreadBadge()
      showToast('已全部标记为已读')
    } catch (_) { /* request.ets 已统一 toast */ }
  }

  @Builder Item(m: MessageItem) {
    Row() {
      Stack() {
        Column().width(44).height(44).borderRadius(12).backgroundColor(this.styleOf(m.type).bg)
        SymbolGlyph($r(this.styleOf(m.type).icon))
          .fontSize(24)
          .fontColor([this.styleOf(m.type).color])
      }.margin({ right: 12 })

      Column() {
        Row() {
          Text(m.title).fontSize(20).fontWeight(600).fontColor($r('app.color.text_primary'))
          if (m.isRead === 0) {
            Circle().width(8).height(8).fill($r('app.color.danger')).margin({ left: 8 })
          }
          Blank()
          Text(this.fmtTime(m.createdAt)).fontSize(15).fontColor($r('app.color.text_hint'))
        }.width('100%')

        Text(m.content)
          .fontSize(17).fontColor($r('app.color.text_secondary')).margin({ top: 6 })
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }
    .width('92%').padding(16).alignSelf(ItemAlign.Center)
    .backgroundColor($r('app.color.bg_card')).borderRadius($r('app.float.radius_lg'))
    .margin({ top: 12 })
    .onClick(() => { this.tapItem(m) })
  }

  build() {
    Column() {
      AppBar({ title: '消息中心' })

      // 全部已读操作行
      Row() {
        Blank()
        Text('全部已读')
          .fontSize(17).fontColor($r('app.color.text_blue'))
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => { this.readAll() })
      }
      .width('92%').alignSelf(ItemAlign.Center)

      if (this.list.length === 0) {
        Column() {
          SymbolGlyph($r(AppIcon.emptyBox))
            .fontSize(56)
            .fontColor([$r('app.color.text_hint')])
          Text(this.loading ? '加载中...' : '暂无消息')
            .fontSize(20).fontColor($r('app.color.text_hint')).margin({ top: 12 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.list, (m: MessageItem) => {
            ListItem() { this.Item(m) }.width('100%')
          }, (m: MessageItem) => m.id)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .onReachEnd(() => { this.loadMore() })
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
