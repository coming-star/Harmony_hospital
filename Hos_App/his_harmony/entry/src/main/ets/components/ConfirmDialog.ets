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
import { promptAction } from '@kit.ArkUI'

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
      else promptAction.showToast({ message: this.confirmText })
    } catch (_) {}
  }
  private no(): void {
    if (this.onCancel) this.onCancel()
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize($r('app.float.fs_18'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: $r('app.float.sp_20'), bottom: $r('app.float.sp_12') })

      Text(this.message)
        .fontSize($r('app.float.fs_14'))
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .margin({ left: $r('app.float.sp_20'), right: $r('app.float.sp_20'), bottom: $r('app.float.sp_24') })
        .layoutWeight(1)

      Row() {
        Button(this.cancelText, { type: ButtonType.Normal })
          .layoutWeight(1)
          .height($r('app.float.btn_height_md'))
          .backgroundColor($r('app.color.bg_page'))
          .fontColor($r('app.color.text_secondary'))
          .fontSize($r('app.float.fs_16'))
          .margin({ right: $r('app.float.sp_12') })
          .onClick(() => this.no())

        Button(this.confirmText, { type: ButtonType.Normal })
          .layoutWeight(1)
          .height($r('app.float.btn_height_md'))
          .backgroundColor(this.danger ? $r('app.color.danger') : $r('app.color.primary'))
          .fontColor($r('app.color.text_white'))
          .fontSize($r('app.float.fs_16'))
          .onClick(() => this.ok())
      }
      .width('100%')
      .padding({ left: $r('app.float.sp_20'), right: $r('app.float.sp_20'), bottom: $r('app.float.sp_20') })
    }
    .width('80%')
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius($r('app.float.radius_lg'))
  }
}
