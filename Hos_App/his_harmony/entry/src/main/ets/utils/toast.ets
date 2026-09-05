/**
 * 全局自定义 Toast：系统 promptAction.showToast 无法调整字体大小，
 * 这里用 ComponentContent + openCustomDialog 实现同样式白色气泡，字号加大到 20（默认约 14 + 6pt）。
 * EntryAbility.onWindowStageCreate 中调用 registerMainWindow 注入主窗口；
 * 未注入或异常时自动回退系统 toast，保证任何场景都有提示。
 */
import { window, promptAction, ComponentContent } from '@kit.ArkUI'

/** 提示字号（系统默认约 14，用户要求增大 6pt） */
const TOAST_FONT_SIZE = 20
const DEFAULT_DURATION = 2000

let mainWindow: window.Window | undefined = undefined
let current: ComponentContent<ToastParam> | undefined = undefined
let currentUi: UIContext | undefined = undefined

/** Toast 气泡参数 */
export class ToastParam {
  message: string = ''
}

@Builder
function toastBubble(param: ToastParam) {
  Column() {
    Text(param.message)
      .fontSize(TOAST_FONT_SIZE)
      .fontColor($r('app.color.text_primary'))
      .textAlign(TextAlign.Center)
  }
  .constraintSize({ maxWidth: 360 })
  .padding({ left: 24, right: 24, top: 14, bottom: 14 })
  .backgroundColor(Color.White)
  .borderRadius(16)
  .shadow({ radius: 24, color: 'rgba(0,0,0,0.12)', offsetX: 0, offsetY: 4 })
}

/** 在 EntryAbility.onWindowStageCreate 里注册主窗口，供 toast 获取 UIContext */
export function registerMainWindow(w: window.Window): void {
  mainWindow = w
}

function dismiss(): void {
  if (current === undefined || currentUi === undefined) return
  const c: ComponentContent<ToastParam> = current
  try { currentUi.getPromptAction().closeCustomDialog(c) } catch (e) { }
  current = undefined
  currentUi = undefined
}

function fallback(message: string, duration: number): void {
  try { promptAction.showToast({ message: message, duration: duration }) } catch (e) { }
}

/** 显示大字号提示气泡（替代 promptAction.showToast） */
export function showToast(message: string, duration: number = DEFAULT_DURATION): void {
  try {
    if (mainWindow === undefined) { fallback(message, duration); return }
    const ui: UIContext = mainWindow.getUIContext()
    dismiss()
    const param: ToastParam = new ToastParam()
    param.message = message
    const content: ComponentContent<ToastParam> = new ComponentContent<ToastParam>(ui, wrapBuilder(toastBubble), param)
    current = content
    currentUi = ui
    const opts: promptAction.BaseDialogOptions = {
      isModal: false,
      alignment: DialogAlignment.Bottom,
      offset: { dx: 0, dy: -140 },
      autoCancel: false,
      maskColor: Color.Transparent
    }
    ui.getPromptAction().openCustomDialog(content, opts).then(() => {
      setTimeout(() => {
        try { ui.getPromptAction().closeCustomDialog(content) } catch (e) { }
        if (current === content) { current = undefined; currentUi = undefined }
      }, duration)
    }).catch(() => { fallback(message, duration) })
  } catch (e) {
    fallback(message, duration)
  }
}
