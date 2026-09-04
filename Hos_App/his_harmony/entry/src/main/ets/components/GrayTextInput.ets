/**
 * 灰底圆角输入框（参考图登录/注册/搜索/AI发送栏统一风格）。
 * 浅灰背景 `input_bg` + 大圆角 16vp，**无边框**；focused 时保持同一底色不改。
 * 用法：
 *   GrayTextInput({
 *     label: '手机号',
 *     placeholder: '请输入手机号',
 *     value: $phone,
 *     type: InputType.PhoneNumber
 *   })
 *   GrayTextInput({
 *     label: '密码',
 *     placeholder: '请输入登录密码',
 *     value: $password,
 *     type: InputType.Password,
 *     rightEye: true
 *   })
 */
@Component
export struct GrayTextInput {
  @Prop label: string = ''                          // 输入框上方文字（参考图登录页"手机号""密码"等）
  @Prop placeholder: string = ''
  @Link value: string
  @Prop type: InputType = InputType.Normal
  @Prop rightEye: boolean = false                   // 密码框显示「👁」眼睛按钮
  @State eyeOpen: boolean = false                   // 眼睛打开=明文显示
  onSubmit?: () => void

  build() {
    Column() {
      if (this.label.length > 0) {
        Text(this.label)
          .fontSize($r('app.float.fs_20'))
          .fontWeight(500)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .margin({ bottom: 15 })
      }

      Row() {
        TextInput({ placeholder: this.placeholder, text: this.value })
          .type(this.rightEye ? (this.eyeOpen ? InputType.Normal : InputType.Password) : this.type)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(52)
          .placeholderColor($r('app.color.text_hint'))
          .fontColor($r('app.color.text_primary'))
          .fontSize($r('app.float.fs_28'))
          .onChange((v) => { this.value = v })
          .onSubmit(() => { if (this.onSubmit) this.onSubmit() })

        if (this.rightEye) {
          Text(this.eyeOpen ? '🙈' : '👁').fontSize(24)
            .width(36).height(36).textAlign(TextAlign.Center)
            .onClick(() => { this.eyeOpen = !this.eyeOpen })
        }
      }
      .width('100%')
      .padding({ left: 12, right: 8 })
      .height(56)
      .backgroundColor($r('app.color.input_bg'))
      .borderRadius($r('app.float.radius_md'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
