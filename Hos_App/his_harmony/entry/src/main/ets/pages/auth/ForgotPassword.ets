/**
 * 找回密码页（短信验证码重置）
 * 蓝顶 AppBar（"找回密码"左返回）+ 手机号 / 验证码（60 秒倒计时）/ 新密码 / 确认新密码
 * + 蓝圆角大"重置密码"按钮；本地模拟验证码打印在后端控制台日志
 */
import { AppBar } from '../../components/AppBar'
import { GrayTextInput } from '../../components/GrayTextInput'
import { PrimaryButton } from '../../components/PrimaryButton'
import router from '@ohos.router'
import { showToast } from '../../utils/toast'
import { Route } from '../../utils/theme'
import * as authApi from '../../api/auth'
import type { SmsResetPasswordRequest } from '../../types'
import { inputMethod } from '@kit.IMEKit'

@Entry
@Component
struct ForgotPassword {
  @State phone: string = ''
  @State smsCode: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''
  @State countdown: number = 0
  @State loading: boolean = false
  private timerId: number = -1

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  /** 发送重置密码验证码（本地模拟）+ 60 秒倒计时 */
  private async sendCode(): Promise<void> {
    if (this.countdown > 0) return
    if (!/^1[3-9]\d{9}$/.test(this.phone)) { showToast('请输入正确的手机号'); return }
    try {
      await authApi.sendSmsCode({ phone: this.phone, scene: 'RESET_PASSWORD' })
      showToast('验证码已发送，请查看后端控制台日志')
      this.countdown = 60
      this.timerId = setInterval(() => {
        this.countdown--
        if (this.countdown <= 0 && this.timerId !== -1) {
          clearInterval(this.timerId)
          this.timerId = -1
        }
      }, 1000)
    } catch (_) {}
  }

  private validate(): boolean {
    if (!/^1[3-9]\d{9}$/.test(this.phone)) { showToast('请输入正确的手机号'); return false }
    if (!/^\d{6}$/.test(this.smsCode)) { showToast('请输入 6 位短信验证码'); return false }
    if (this.newPassword.length < 8) { showToast('新密码至少 8 位'); return false }
    if (this.newPassword !== this.confirmPassword) { showToast('两次输入的密码不一致'); return false }
    return true
  }

  private async submit(): Promise<void> {
    if (this.loading || !this.validate()) return
    this.loading = true
    try {
      const body: SmsResetPasswordRequest = {
        phone: this.phone,
        code: this.smsCode,
        newPassword: this.newPassword
      }
      await authApi.resetPasswordBySms(body)
      showToast('密码重置成功，请使用新密码登录')
      router.replaceUrl({ url: Route.LOGIN })
    } catch (_) {}
    finally { this.loading = false }
  }

  build() {
    Column() {
      AppBar({ title: '找回密码' })

      Scroll() {
        Column() {
          Text('通过注册手机号验证码重置登录密码')
            .fontSize(20).fontColor($r('app.color.text_secondary'))
            .margin({ top: 24, bottom: 28 })

          Column({ space: 25 }) {
            GrayTextInput({
              label: '手机号',
              placeholder: '请输入注册手机号',
              value: $phone,
              type: InputType.PhoneNumber
            })

            // 验证码输入行：灰底输入框 + 蓝色"获取验证码"按钮
            Column() {
              Text('验证码')
                .fontSize(22).fontWeight(500)
                .fontColor($r('app.color.text_primary'))
                .width('100%').margin({ bottom: 15 })
              Row() {
                TextInput({ placeholder: '请输入 6 位验证码', text: this.smsCode })
                  .type(InputType.Number)
                  .maxLength(6)
                  .backgroundColor(Color.Transparent)
                  .layoutWeight(1)
                  .height(54)
                  .placeholderColor($r('app.color.text_hint'))
                  .fontColor($r('app.color.text_primary'))
                  .fontSize(30)
                  .onChange((v: string) => { this.smsCode = v })
                  .onClick(() => {})
                Text(this.countdown > 0 ? `${this.countdown}s 后重发` : '获取验证码')
                  .fontSize(20)
                  .fontWeight(600)
                  .fontColor(this.countdown > 0
                    ? $r('app.color.text_hint') : $r('app.color.text_blue'))
                  .padding({ left: 10, right: 4 })
                  .onClick(() => { this.sendCode() })
              }
              .width('100%')
              .padding({ left: 12, right: 8 })
              .height(60)
              .backgroundColor($r('app.color.input_bg'))
              .borderRadius($r('app.float.radius_md'))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            GrayTextInput({
              label: '新密码',
              placeholder: '请输入新密码（至少 8 位）',
              value: $newPassword,
              type: InputType.Password,
              rightEye: true
            })
            GrayTextInput({
              label: '确认新密码',
              placeholder: '请再次输入新密码',
              value: $confirmPassword,
              type: InputType.Password,
              rightEye: true
            })
          }.width('80%')

          PrimaryButton({ label: '重置密码', isEnabled: !this.loading, onTap: () => this.submit() })
            .width('80%').margin({ top: 40 })
        }
        .width('100%').alignItems(HorizontalAlign.Center)
      }.layoutWeight(1).scrollBar(BarState.Off)
       // 点击表单外的空白区收起软键盘
       .onClick(() => { inputMethod.getController().hideTextInput() })
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }
}
