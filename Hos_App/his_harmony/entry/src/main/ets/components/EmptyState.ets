/**
 * 空态组件：图标占位 + "暂无数据" 文案 + 可选「去添加/重试」按钮
 *
 * 用法：
 *   EmptyState({ hint: '还没有挂号记录', actionText: '去预约', onAction: ()=>router.pushUrl(...) })
 */
import router from '@ohos.router'

@Component
export struct EmptyState {
  @Prop hint: string = '暂无数据'
  /** 表情符号占位（目前用文字符号代替图片，不占 apk 大小）*/
  @Prop emoji: string = '📭'
  /** 传了就显示动作按钮 */
  @Prop actionText: string = ''
  /** 不传动作又传了 routeTo，动作按钮就是跳某页面 */
  @Prop routeTo: string = ''
  onAction?: () => void

  private doAction(): void {
    if (this.onAction) { this.onAction(); return }
    if (this.routeTo) {
      try { router.pushUrl({ url: this.routeTo }) } catch (_) {}
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
        Button(this.actionText, { type: ButtonType.Capsule })
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

