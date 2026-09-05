/**
 * 统一二次确认弹窗：用户点击"退出登录 / 取消订单 / 删除就诊人"等危险操作前弹出。
 *
 * 用法：
 *   @State confirmShow = false
 *   ConfirmDialog({
 *     show: $confirmShow,
 *     title: '温馨提示',
 *     message: '确定要退出登录吗？',
 *     confirmText: '确定',
 *     cancelText: '取消',
 *     danger: true,
 *     onConfirm: () => userStore.logout()
 *   })
 */
import { showToast } from '../utils/toast'

@Component
export struct ConfirmDialog {
  @Prop title: string = '温馨提示'
  @Prop message: string = ''
  @Prop confirmText: string = '确定'
  @Prop cancelText: string = '取消'
  /** 危险操作（确认按钮变红）*/
  @Prop danger: boolean = false
  onConfirm?: () => void
  onCancel?: () => void

  private ok(): void {
    try {
      if (this.onConfirm) this.onConfirm()
      else showToast(this.confirmText)
    } catch (_) {}
  }
  private no(): void {
    if (this.onCancel) this.onCancel()
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 24, bottom: 16 })

      Text(this.message)
        .fontSize(24)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .margin({ left: 20, right: 20, bottom: 28 })

      Row() {
        Button(this.cancelText, { type: ButtonType.Normal })
          .layoutWeight(1)
          .height(48)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_secondary'))
          .fontSize(22)
          .margin({ right: 12 })
          .onClick(() => this.no())

        Button(this.confirmText, { type: ButtonType.Normal })
          .layoutWeight(1)
          .height(48)
          .backgroundColor(this.danger ? $r('app.color.danger') : $r('app.color.primary'))
          .fontColor($r('app.color.text_white'))
          .fontSize(22)
          .onClick(() => this.ok())
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
    }
    .width('85%')
    .backgroundColor($r('app.color.sheet_bg'))
    .borderRadius($r('app.float.radius_lg'))
  }
}
