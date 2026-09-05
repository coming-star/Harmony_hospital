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
          .fontSize(22)
          .fontWeight(500)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .margin({ bottom: 15 })
      }

      Row() {
        TextInput({ placeholder: this.placeholder, text: this.value })
          .type(this.type)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .height(54)
          .placeholderColor($r('app.color.text_hint'))
          .fontColor($r('app.color.text_primary'))
          .fontSize(30)
          .onChange((v) => { this.value = v })
          .onSubmit(() => { if (this.onSubmit) this.onSubmit() })
          // 空回调消费点击事件，防止冒泡到页面的「点击空白收起键盘」onClick
          .onClick(() => {})
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
}
