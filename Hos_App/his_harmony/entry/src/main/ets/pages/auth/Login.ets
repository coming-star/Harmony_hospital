/**
 * 登录页（完全匹配参考图）
 * 蓝顶 AppBar（"登录"左返回）+ 居中听诊器大图标 + 欢迎回来 + 登录东软...灰subtitle
 * + 登录方式切换（密码登录 / 验证码登录）+ 手机号/密码灰底圆角输入（密码右侧小眼睛）
 * + 验证码登录：灰底输入框 + 蓝色"获取验证码"按钮（60 秒倒计时，本地模拟验证码看后端日志）
 * + 用户协议复选框 + 忘记密码入口 + 蓝圆角大登录按钮 + 底部"还没有账号？立即注册"蓝字
 */
import { AppBar } from '../../components/AppBar'
import { StethoscopeIcon } from '../../components/StethoscopeIcon'
import { GrayTextInput } from '../../components/GrayTextInput'
import { PrimaryButton } from '../../components/PrimaryButton'
import router from '@ohos.router'
import { showToast } from '../../utils/toast'
import userStore from '../../store/UserStore'
import { Route } from '../../utils/theme'
import * as authApi from '../../api/auth'
import type { AppLoginRequest, LoginResponse, SmsLoginRequest } from '../../types'
import { inputMethod } from '@kit.IMEKit'

@Entry
@Component
struct Login {
  @State loginMode: string = 'password'      // 'password' 密码登录 | 'sms' 验证码登录
  @State phone: string = ''
  @State password: string = ''
  @State smsCode: string = ''
  @State countdown: number = 0               // 获取验证码倒计时（秒）
  @State agreed: boolean = false
  @State loading: boolean = false
  private timerId: number = -1

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  private validate(): boolean {
    if (!/^1[3-9]\d{9}$/.test(this.phone)) { showToast('请输入正确的手机号'); return false }
    if (this.loginMode === 'password' && this.password.length < 6) { showToast('密码至少 6 位'); return false }
    if (this.loginMode === 'sms' && !/^\d{6}$/.test(this.smsCode)) { showToast('请输入 6 位短信验证码'); return false }
    if (!this.agreed) { showToast('请先阅读并同意《用户协议》与《隐私政策》'); return false }
    return true
  }

  /** 发送短信验证码（本地模拟：验证码打印在后端控制台日志）+ 60 秒倒计时 */
  private async sendCode(): Promise<void> {
    if (this.countdown > 0) return
    if (!/^1[3-9]\d{9}$/.test(this.phone)) { showToast('请输入正确的手机号'); return }
    try {
      await authApi.sendSmsCode({ phone: this.phone, scene: 'LOGIN' })
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

  private async submit(): Promise<void> {
    if (this.loading || !this.validate()) return
    this.loading = true
    try {
      let r: LoginResponse
      if (this.loginMode === 'sms') {
        const body: SmsLoginRequest = { phone: this.phone, code: this.smsCode }
        r = await authApi.smsLogin(body)
      } else {
        const body: AppLoginRequest = { phone: this.phone, password: this.password }
        r = await authApi.login(body)
      }
      await userStore.setLogin(r)
      showToast('登录成功')
      router.replaceUrl({ url: Route.HOME })
    } catch (_) {}
    finally { this.loading = false }
  }

  build() {
    Column() {
      AppBar({ title: '登录' })

      Scroll() {
        Column() {
          // 听诊器大 logo
          StethoscopeIcon({ customSize: 108 }).margin({ top: 20, bottom: 16 })
          Text('欢迎回来').fontSize(32).fontWeight(800).fontColor($r('app.color.text_primary'))
            .margin({ bottom: 10 })
          Text('登录东软云医院预约挂号系统')
            .fontSize(19).fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 24 })

          // 登录方式切换（密码登录 / 验证码登录）
          Row({ space: 32 }) {
            Text('密码登录')
              .fontSize(24)
              .fontWeight(this.loginMode === 'password' ? 700 : 400)
              .fontColor(this.loginMode === 'password'
                ? $r('app.color.primary') : $r('app.color.text_hint'))
              .onClick(() => { this.loginMode = 'password' })
            Text('验证码登录')
              .fontSize(24)
              .fontWeight(this.loginMode === 'sms' ? 700 : 400)
              .fontColor(this.loginMode === 'sms'
                ? $r('app.color.primary') : $r('app.color.text_hint'))
              .onClick(() => { this.loginMode = 'sms' })
          }
          .width('80%').justifyContent(FlexAlign.Center).margin({ bottom: 24 })

          Column({ space: 25 }) {
            GrayTextInput({
              label: '手机号',
              placeholder: '请输入手机号',
              value: $phone,
              type: InputType.PhoneNumber
            })
            if (this.loginMode === 'password') {
              GrayTextInput({
                label: '密码',
                placeholder: '请输入密码',
                value: $password,
                type: InputType.Password,
                rightEye: true
              })
            } else {
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
            }
          }.width('80%')

          // 协议 checkbox
          Row() {
            Checkbox({ name: 'agree' })
              .select(this.agreed)
              .selectedColor($r('app.color.primary'))
              .onChange(v => { this.agreed = v })
            Text('我已阅读并同意')
              .fontSize(18).fontColor($r('app.color.text_secondary'))
              .margin({ left: 6 })
            Text('《用户协议》').fontSize(18).fontColor($r('app.color.text_blue'))
            Text('与').fontSize(18).fontColor($r('app.color.text_secondary'))
            Text('《隐私政策》').fontSize(18).fontColor($r('app.color.text_blue'))
          }
          .width('80%').margin({ top: 20, bottom: 32 })
          .justifyContent(FlexAlign.Start)

          // 忘记密码入口（仅密码登录模式显示）
          if (this.loginMode === 'password') {
            Row() {
              Blank()
              Text('忘记密码？')
                .fontSize(20)
                .fontColor($r('app.color.text_blue'))
                .onClick(() => { try { router.pushUrl({ url: Route.FORGET_PASSWORD }) } catch (_) {} })
            }
            .width('80%').margin({ bottom: 16 })
          }

          PrimaryButton({ label:'登录', isEnabled:!this.loading, onTap: () => this.submit() })
            .width('80%').margin({ bottom: 16 })

          Row() {
            Text('还没有账号？').fontSize(20).fontColor($r('app.color.text_hint'))
            Text('立即注册').fontSize(20).fontColor($r('app.color.text_blue')).fontWeight(600)
              .onClick(() => { try { router.pushUrl({ url: Route.REGISTER }) } catch (_) {} })
          }.margin({ top: 8, bottom: 24 })
        }
        .width('100%').alignItems(HorizontalAlign.Center)
      }.layoutWeight(1).scrollBar(BarState.Off)
       // 点击表单外的空白区收起软键盘（输入框自身已拦截冒泡）
       .onClick(() => { inputMethod.getController().hideTextInput() })
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }
}
