/**
 * 【AI Tab】匹配参考图第三张：
 * 顶部蓝色 AppBar（"🤖 AI健康管家" + 右上 ⚙️ 齿轮图标）
 * + "尚未配置AI接入信息，点击前往设置"灰色提示条
 * + 气泡对话（左侧 AI 蓝灰气泡 / 右侧用户 品牌蓝 气泡）
 * + 底部输入栏（灰底圆角输入框"输入你的问题…"+ 蓝色圆角纸飞机发送按钮）
 */
import { AppBar } from '../components/AppBar'
import { Format } from '../utils/format'
import { Route } from '../utils/theme'
import router from '@ohos.router'

interface Msg { id: string; role: 'user'|'ai'; content: string }

@Component
export struct AITab {
  @State list: Msg[] = [
    { id: Format.uuid(), role:'ai', content:'你好！我是 AI 健康管家，可以为你解答健康问题、查询科室医生、协助预约挂号。'}
  ]
  @State input: string = ''
  @State setupShow: boolean = false
  private scroller: Scroller = new Scroller()

  private send(): void {
    const text: string = this.input.trim()
    if (!text) return
    this.list.push({ id: Format.uuid(), role:'user', content: text })
    this.input = ''
    this.scroller.scrollEdge(Edge.Bottom)
    setTimeout(() => {
      this.list.push({
        id: Format.uuid(),
        role:'ai',
        content: `（mock）收到咨询：「${text}」。根据描述建议您先挂心血管内科或全科进一步检查。`
      })
      this.scroller.scrollEdge(Edge.Bottom)
    }, 500)
  }

  @Builder Bubble(m: Msg) {
    Row() {
      if (m.role === 'ai') {
        Column() { Text(m.content)
            .fontSize(14).fontColor($r('app.color.text_primary'))
            .padding(14).maxLines(999) }
          .backgroundColor($r('app.color.bg_card'))
          .borderRadius($r('app.float.radius_md'))
          .margin({ right: 64 })
          .layoutWeight(1)
      } else {
        Blank()
        Column() { Text(m.content)
            .fontSize(14).fontColor($r('app.color.text_white'))
            .padding(14).maxLines(999) }
          .backgroundColor($r('app.color.primary'))
          .borderRadius($r('app.float.radius_md'))
          .margin({ left: 64 })
          .layoutWeight(1)
      }
    }
    .width('100%').margin({bottom:12})
    .padding({ left: 16, right: 16 })
  }

  build() {
    Column() {
      AppBar({ title: 'AI健康管家', hideBack: true,
        rightIcon: '⚙️', onRightClick: () => { this.setupShow = !this.setupShow } })

      // 设置提示条
      Row() {
        Text('💡').fontSize(14).margin({right:8})
        Text('尚未配置AI接入信息，点击前往设置')
          .fontSize(13).fontColor($r('app.color.text_secondary'))
      }
      .width('92%').padding(12).margin({top:12, bottom:8})
      .backgroundColor($r('app.color.primary_light'))
      .borderRadius($r('app.float.radius_md'))
      .onClick(() => { try { router.pushUrl({ url: Route.SETTINGS }) } catch (e) {} })

      List({ space:0, scroller: this.scroller }) {
        ForEach(this.list, (m: Msg) => {
          ListItem() { this.Bubble(m) }.width('100%')
        }, (m: Msg) => m.id)
      }.layoutWeight(1).padding({top:8,bottom:8}).scrollBar(BarState.Off)

      // 底部输入栏（参考图同款：灰输入框 + 蓝圆角发送按钮）
      Row() {
        TextInput({ placeholder:'输入你的问题...', text: this.input })
          .layoutWeight(1).height(44)
          .backgroundColor($r('app.color.input_bg'))
          .borderRadius($r('app.float.radius_md'))
          .padding({left:14,right:14})
          .placeholderColor($r('app.color.text_hint'))
          .onChange(v => this.input = v)
          .onSubmit(() => this.send())

        Stack({alignContent:Alignment.Center}) {
          Column().width(44).height(44).borderRadius(14).backgroundColor($r('app.color.primary'))
          Text('✈').fontSize(22).fontColor($r('app.color.text_white'))
        }
        .margin({left:12})
        .onClick(() => this.send())
      }.width('100%').padding(12).backgroundColor($r('app.color.bg_card'))
       .borderWidth({top:0.5}).borderColor($r('app.color.divider'))
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
