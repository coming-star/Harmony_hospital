/**
 * 【我的 Tab】完全匹配参考图右侧第 4 张：
 * 1. 蓝色顶部：圆形头像（首字母）+ 大号昵称 + 蓝色小字手机号（健康用户 / 186xxxx）
 * 2. 三张圆角白卡：挂号记录 / 就诊人管理 / AI管家设置（每张 方框图标+主文灰副文+右侧 › 箭头）
 * 3. 系统信息分组：系统名称 / 技术栈 键值对
 * 4. 红色"退出登录"按钮（弹 ConfirmDialog 二次确认）
 */
import router from '@ohos.router'
import userStore from '../../store/UserStore.ets'
import { AvatarIcon } from '../../components/AvatarIcon.ets'
import { ConfirmDialog } from '../../components/ConfirmDialog.ets'
import { Route } from '../../utils/theme.ets'

interface EntryRow {
  key: string
  glyph: string
  title: string
  sub: string
  route?: string
  disabled?: boolean
}
interface InfoRow {
  key: string
  value: string
}

@Component
export struct MineTab {
  @State logoutShow = false
  private readonly entries: EntryRow[] = [
    { key:'orders',   glyph:'📄', title:'挂号记录',     sub:'查看历史挂号',           route: Route.ORDER_RECORD },
    { key:'contacts', glyph:'🧑‍🤝‍🧑', title:'就诊人管理',   sub:'管理绑定就诊人',           route: Route.CONTACT_MGNT },
    { key:'ai',       glyph:'⚙️', title:'AI管家设置',   sub:'配置AI接入信息' }
  ]
  private readonly systemInfos: InfoRow[] = [
    { key:'系统名称', value:'东软云医院预约挂号系统' },
    { key:'技术栈',   value:'HarmonyOS · ArkTS · Spring Boot 3' }
  ]

  private click(r: EntryRow) {
    if (r.disabled || !r.route) return
    try { router.pushUrl({ url: r.route }) } catch(_) {}
  }

  @Builder BlueTopHeader() {
    Stack({alignContent:Alignment.BottomStart}) {
      Column()
        .width('100%').height(200)
        .backgroundColor($r('app.color.primary'))

      Row() {
        AvatarIcon({ name: userStore.nickname || '健康用户', size: 72 })
        Column() {
          Text(userStore.nickname ? userStore.nickname : '健康用户')
            .fontSize(22).fontWeight(800).fontColor($r('app.color.text_white'))
          if (userStore.isLoggedIn()) {
            Text(`手机号 ${userStore.token ? '186****3116' : ''}`)
              .fontSize(13).fontColor('#CCFFFFFF').margin({top:4})
          } else {
            Text('未登录，点击这里登录').fontSize(13).fontColor('#CCFFFFFF')
              .margin({top:4}).padding(4)
              .onClick(() => { try { router.pushUrl({ url: Route.LOGIN }) } catch(_){} })
          }
        }.margin({ left: 16 }).layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('92%').padding({ left: 0, right: 0, bottom: 20 })
      .margin({ left: 16, right: 16, bottom: -24 })   // 底部浮到下方白卡
    }
    .width('100%').height(200)
  }

  @Builder EntryCard(r: EntryRow) {
    Row() {
      // 图标方框（参考图：左灰方框）
      Stack() {
        RoundedRect({width:44,height:44,radius:10}).fill($r('app.color.primary_light'))
        Text(r.glyph).fontSize(22)
      }.margin({ right: 14 })

      Column().layoutWeight(1).alignItems(HorizontalAlign.Start) {
        Text(r.title).fontSize(16).fontWeight(600).fontColor($r('app.color.text_primary'))
        Text(r.sub).fontSize(12).fontColor($r('app.color.text_secondary')).margin({ top: 4 })
      }
      Text('›').fontSize(28).fontColor($r('app.color.text_hint'))
    }
    .width('92%').padding(18).alignSelf(ItemAlign.Center)
    .backgroundColor($r('app.color.bg_card')).borderRadius(16)
    .margin({ top: 12 })
    .onClick(() => this.click(r))
  }

  @Builder InfoGroup() {
    Column() {
      Text('系统信息').fontSize(12).fontColor($r('app.color.text_hint'))
        .width('92%').alignSelf(ItemAlign.Start).margin({ left: 0, top: 24, bottom: 8 })

      Column() {
        ForEach(this.systemInfos, (it: InfoRow, idx: number) => {
          Row() {
            Text(it.key).fontSize(14).fontColor($r('app.color.text_secondary')).layoutWeight(1)
            Text(it.value).fontSize(14).fontColor($r('app.color.text_primary'))
          }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })

          if (idx < this.systemInfos.length - 1) {
            Divider().color($r('app.color.divider')).margin({ left: 16 })
          }
        }, (it) => it.key)
      }
      .width('92%')
      .backgroundColor($r('app.color.bg_card')).borderRadius(16)
      .alignSelf(ItemAlign.Center)
    }
    .width('100%')
  }

  build() {
    Column() {
      this.BlueTopHeader()

      // 3 张入口卡
      ForEach(this.entries, it => {
        this.EntryCard(it)
      }, (it) => it.key)

      this.InfoGroup()

      // 退出登录（红色大圆角按钮，白边红字，参考图同款）
      Button('退出登录', ButtonType.Normal)
        .width('92%').height(50)
        .margin({ top: 36, bottom: 40 })
        .backgroundColor($r('app.color.danger_light'))
        .fontColor($r('app.color.danger'))
        .fontSize(15).fontWeight(600)
        .borderRadius($r('app.float.radius_lg'))
        .onClick(() => { this.logoutShow = true })
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .bindSheet($$$this.logoutShow,
      ConfirmDialog({
        show: $$$this.logoutShow,
        message: '确定要退出登录吗？',
        danger: true,
        onConfirm: () => { userStore.logout() }
      }), { height: 280, preferType: SheetType.CENTER, showClose: false, dragBar: true })
  }
}
