/**
 * 注册页（完全匹配参考图）
 * 蓝顶"注册"+听诊器+创建账号/注册后即可…+ 手机号/密码/确认密码 灰底输入框
 * + 协议 + 蓝色大圆角"注册并登录"+ 底部"已有账号？去登录"
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
import type { AppRegisterRequest, LoginResponse } from '../../types'

@Entry
@Component
struct Register {
  @State phone: string = ''
  @State password: string = ''
  @State confirm: string = ''
  @State agreed: boolean = false
  @State loading: boolean = false

  private valid(): boolean {
    if (!/^1[3-9]\d{9}$/.test(this.phone)) { promptAction.showToast({ message:'手机号格式不正确' }); return false }
    if (this.password.length < 8) { promptAction.showToast({ message:'密码至少 8 位' }); return false }
    if (this.password !== this.confirm) { promptAction.showToast({ message:'两次密码不一致' }); return false }
    if (!this.agreed) { promptAction.showToast({ message:'请先同意《用户协议》与《隐私政策》' }); return false }
    return true
  }
  private async submit(): Promise<void> {
    if (this.loading || !this.valid()) return
    this.loading = true
    try {
      const body: AppRegisterRequest = {
        phone: this.phone,
        password: this.password,
        nickname: this.phone.slice(-4)   // 默认昵称（手机后4位），真实场景让用户再填
      }
      const r: LoginResponse = await authApi.register(body)
      await userStore.setLogin(r)
      promptAction.showToast({ message: '注册成功' })
      router.replaceUrl({ url: Route.HOME })
    } catch (_) {}
    finally { this.loading = false }
  }

  build() {
    Column() {
      AppBar({ title: '注册' })
      Scroll() {
        Column() {
          StethoscopeIcon({ customSize: 108 }).margin({ top: 20, bottom: 16 })
          Text('创建账号').fontSize(32).fontWeight(800).fontColor($r('app.color.text_primary')).margin({bottom:8})
          Text('注册后即可在线预约挂号').fontSize(15).fontColor($r('app.color.text_secondary')).margin({bottom:24})

          Column({ space: 25 }) {
            GrayTextInput({ label:'手机号', placeholder:'请输入手机号', value: $phone, type: InputType.PhoneNumber })
            GrayTextInput({ label:'密码', placeholder:'请设置密码（至少8位）', value: $password, type: InputType.Password, rightEye: true })
            GrayTextInput({ label:'确认密码', placeholder:'请再次输入密码', value: $confirm, type: InputType.Password, rightEye: true })
          }.width('80%')

          Row() {
            Checkbox({name:'agree'}).select(this.agreed).selectedColor($r('app.color.primary'))
              .onChange(v => this.agreed = v)
            Text('我已阅读并同意').fontSize(14).fontColor($r('app.color.text_secondary')).margin({left:6})
            Text('《用户协议》').fontSize(14).fontColor($r('app.color.text_blue'))
            Text('与').fontSize(14).fontColor($r('app.color.text_secondary'))
            Text('《隐私政策》').fontSize(14).fontColor($r('app.color.text_blue'))
          }.width('80%').justifyContent(FlexAlign.Start).margin({ top: 20, bottom: 32 })

          PrimaryButton({ label:'注册并登录', isEnabled:!this.loading, onTap: () => this.submit() })
            .width('80%').margin({ bottom: 16 })

          Row() {
            Text('已有账号？').fontSize(14).fontColor($r('app.color.text_hint'))
            Text('去登录').fontSize(14).fontColor($r('app.color.text_blue')).fontWeight(600)
              .onClick(() => { try { router.replaceUrl({ url: Route.LOGIN }) } catch (_) {} })
          }.margin({ top: 8, bottom: 24 })
        }.width('100%').alignItems(HorizontalAlign.Center)
      }.layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
