/**
 * 空态组件：图标占位 + "暂无数据" 文案 + 可选「去添加/重试」按钮
 *
 * 用法：
 *   EmptyState({ hint: '还没有挂号记录', actionText: '去预约', onAction: ()=>router.pushUrl(...) })
 */
import router from '@ohos.router'
import { Route } from '../utils/theme'

@Component
export struct EmptyState {
  @Prop hint: string = '暂无数据'
  /** 表情符号占位（目前用文字符号代替图片，不占 apk 大小）*/
  @Prop emoji: string = '📭'
  /** 传了就显示动作按钮 */
  @Prop actionText?: string
  /** 不传动作又传了 routeTo，动作按钮就是跳某页面 */
  @Prop routeTo?: string
  @Link? onAction?: () => void

  private doAction(): void {
    if (this.onAction) { this.onAction(); return }
    if (this.routeTo) {
      try { router.pushUrl({ url: this.routeTo }) } catch(_: Error) {}
    }
  }

  build() {
    Column() {
      Text(this.emoji)
        .fontSize($r('app.float.fs_32'))
        .margin({ bottom: $r('app.float.sp_8') })

      Text(this.hint)
        .fontSize($r('app.float.fs_14'))
        .fontColor($r('app.color.text_hint'))
        .margin({ bottom: $r('app.float.sp_16') })

      if (this.actionText && this.actionText.length > 0) {
        Button(this.actionText, ButtonType.Capsule)
          .height($r('app.float.btn_height_md'))
          .backgroundColor($r('app.color.primary'))
          .fontColor($r('app.color.text_white'))
          .fontSize($r('app.float.fs_14'))
          .padding({ left: $r('app.float.sp_20'), right: $r('app.float.sp_20') })
          .onClick(() => this.doAction())
      }
    }
    .width('100%')
    .padding({
      top: $r('app.float.sp_32'),
      bottom: $r('app.float.sp_32')
    })
  }
}

/** 快速实例：挂号记录页的空态（带"去预约"按钮）*/
export function OrderRecordEmpty({ onGo }: { onGo?: () => void }): EmptyState {
  const e = new EmptyState()
  e.hint = '还没有挂号记录'
  e.emoji = '📋'
  e.actionText = '去预约'
  e.routeTo = Route.APPOINTMENT
  if (onGo) e.onAction = onGo as () => void
  return e
}
