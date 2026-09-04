/**
 * 登录页（完全匹配参考图）
 * 蓝顶 AppBar（"登录"左返回）+ 居中听诊器大图标 + 欢迎回来 + 登录东软...灰subtitle
 * + 手机号/密码灰底圆角输入（密码右侧小眼睛）+ 用户协议复选框
 * + 蓝圆角大登录按钮 + 底部"还没有账号？立即注册"蓝字
 */
import { AppBar } from '../../components/AppBar'
import { StethoscopeIcon } from '../../components/StethoscopeIcon'
import { GrayTextInput } from '../../components/GrayTextInput'
import { PrimaryButton } from '../../components/PrimaryButton'
import router from '@ohos.router'
import { promptAction } from '@kit.ArkUI'
import userStore from '../../store/UserStore'
import { Route } from '../../utils/theme'
import * as authApi from '../../api/auth'
import type { AppLoginRequest, LoginResponse } from '../../types'

@Entry
@Component
struct Login {
  @State phone: string = ''
  @State password: string = ''
  @State agreed: boolean = false
  @State loading: boolean = false

  private validate(): boolean {
    if (!/^1[3-9]\d{9}$/.test(this.phone)) { promptAction.showToast({ message:'请输入正确的手机号' }); return false }
    if (this.password.length < 6) { promptAction.showToast({ message:'密码至少 6 位' }); return false }
    if (!this.agreed) { promptAction.showToast({ message:'请先阅读并同意《用户协议》与《隐私政策》' }); return false }
    return true
  }
  private async submit(): Promise<void> {
    if (this.loading || !this.validate()) return
    this.loading = true
    try {
      const body: AppLoginRequest = { phone: this.phone, password: this.password }
      const r: LoginResponse = await authApi.login(body)
      await userStore.setLogin(r)
      promptAction.showToast({ message:'登录成功' })
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
          StethoscopeIcon({ customSize: 108 }).margin({ top: 36, bottom: 24 })
          Text('欢迎回来').fontSize(32).fontWeight(800).fontColor($r('app.color.text_primary'))
            .margin({ bottom: 10 })
          Text('登录东软云医院预约挂号系统')
            .fontSize(18).fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 40 })

          Column({ space: 25 }) {
            GrayTextInput({
              label: '手机号',
              placeholder: '请输入手机号',
              value: $phone,
              type: InputType.PhoneNumber
            })
            GrayTextInput({
              label: '密码',
              placeholder: '请输入密码',
              value: $password,
              type: InputType.Password,
              rightEye: true
            })
          }.width('80%')

          // 协议 checkbox
          Row() {
            Checkbox({ name: 'agree' })
              .select(this.agreed)
              .selectedColor($r('app.color.primary'))
              .onChange(v => { this.agreed = v })
            Text('我已阅读并同意')
              .fontSize(20).fontColor($r('app.color.text_secondary'))
              .margin({ left: 6 })
            Text('《用户协议》').fontSize(20).fontColor($r('app.color.text_blue'))
            Text('与').fontSize(20).fontColor($r('app.color.text_secondary'))
            Text('《隐私政策》').fontSize(20).fontColor($r('app.color.text_blue'))
          }
          .width('80%').margin({ top: 20, bottom: 32 })
          .justifyContent(FlexAlign.Start)

          PrimaryButton({ label:'登录', isEnabled:!this.loading, onTap: () => this.submit() })
            .width('80%').margin({ bottom: 16 })

          Row() {
            Text('还没有账号？').fontSize(20).fontColor($r('app.color.text_hint'))
            Text('立即注册').fontSize(20).fontColor($r('app.color.text_blue')).fontWeight(600)
              .onClick(() => { try { router.pushUrl({ url: Route.REGISTER }) } catch (_) {} })
          }.margin({ top: 8, bottom: 40 })
        }
        .width('100%').alignItems(HorizontalAlign.Center)
      }.layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor(Color.White)
  }
}
