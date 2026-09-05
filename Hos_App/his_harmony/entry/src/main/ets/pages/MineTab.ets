/**
 * 【我的 Tab】完全匹配参考图右侧第 4 张：
 * 1. 蓝色顶部：圆形头像（首字母）+ 大号昵称 + 蓝色小字手机号（健康用户 / 186xxxx）
 * 2. 三张圆角白卡：挂号记录 / 就诊人管理 / AI管家设置（每张 方框图标+主文灰副文+右侧 › 箭头）
 * 3. 系统信息分组：系统名称 / 技术栈 键值对
 * 4. 红色"退出登录"按钮（弹 ConfirmDialog 二次确认）
 */
import router from '@ohos.router'
import userStore from '../store/UserStore'
import { AvatarIcon } from '../components/AvatarIcon'
import { ConfirmDialog } from '../components/ConfirmDialog'
import { AppIcon } from '../utils/icons'
import { Format } from '../utils/format'
import { Route } from '../utils/theme'

interface EntryRow {
  key: string
  icon: string
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
  @State logoutShow: boolean = false
  @State nickname: string = ''
  @State phone: string = ''
  private readonly entries: EntryRow[] = [
    { key:'orders',   icon: AppIcon.message, title:'挂号记录',     sub:'查看历史挂号',           route: Route.ORDER_RECORD },
    { key:'contacts', icon: AppIcon.profileOutline, title:'就诊人管理',   sub:'管理绑定就诊人',           route: Route.CONTACT_MGNT },
    { key:'ai',       icon: AppIcon.settings, title:'AI管家设置',   sub:'配置AI接入信息' }
  ]
  private readonly systemInfos: InfoRow[] = [
    { key:'系统名称', value:'东软云医院预约挂号系统' },
    { key:'技术栈',   value:'HarmonyOS · ArkTS · Spring Boot 3' }
  ]

  private click(r: EntryRow): void {
    if (r.disabled || !r.route) return
    try { router.pushUrl({ url: r.route }) } catch (_) {}
  }

  aboutToAppear(): void {
    this.nickname = userStore.nickname
    this.phone = userStore.phone
  }

  @Builder BlueTopHeader() {
    Stack({alignContent:Alignment.Center}) {
      Column()
        .width('100%').height(180)
        .backgroundColor($r('app.color.primary'))

      Row() {
        AvatarIcon({ name: this.nickname || '健康用户', iconSize: 72, bg: $r('app.color.primary_light') })
        Column() {
          Text(this.nickname ? this.nickname : '健康用户')
            .fontSize(28).fontWeight(800).fontColor($r('app.color.text_white'))
          if (userStore.isLoggedIn()) {
            Text(this.phone ? `手机号 ${Format.maskPhone(this.phone)}` : '')
              .fontSize(20).fontColor('#CCFFFFFF').margin({top:6})
          } else {
            Text('未登录，点击这里登录').fontSize(20).fontColor('#CCFFFFFF')
              .margin({top:6}).padding(4)
              .onClick(() => { try { router.pushUrl({ url: Route.LOGIN }) } catch (_) {} })
          }
        }.margin({ left: 16 }).layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('92%')
      .margin({ left: 16, right: 16 })
      .alignSelf(ItemAlign.Start)
    }
    .width('100%').height(180)
  }

  @Builder EntryCard(r: EntryRow) {
    Row() {
      // 图标方框（参考图：左灰方框）
      Stack() {
        Column().width(48).height(48).borderRadius(10).backgroundColor($r('app.color.primary_light'))
        SymbolGlyph($r(r.icon))
          .fontSize(30)
      }.margin({ right: 14 })

      Column() {
        Text(r.title).fontSize(22).fontWeight(600).fontColor($r('app.color.text_primary'))
        Text(r.sub).fontSize(18).fontColor($r('app.color.text_secondary')).margin({ top: 6 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      SymbolGlyph($r(AppIcon.forward))
        .fontSize(30)
    }
    .width('92%').padding(20).alignSelf(ItemAlign.Center)
    .backgroundColor($r('app.color.bg_card')).borderRadius(16)
    .margin({ top: 12 })
    .onClick(() => this.click(r))
  }

  @Builder InfoGroup() {
    Column() {
      Text('系统信息').fontSize(20).fontColor($r('app.color.text_hint'))
        .width('92%').alignSelf(ItemAlign.Start).margin({ left:14, top: 24, bottom: 8 })

      Column() {
        ForEach(this.systemInfos, (it: InfoRow, idx: number) => {
          Row() {
            Text(it.key).fontSize(20).fontColor($r('app.color.text_secondary')).layoutWeight(1)
            Text(it.value).fontSize(20).fontColor($r('app.color.text_primary'))
          }.width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })

          if (idx < this.systemInfos.length - 1) {
            Divider().color($r('app.color.divider')).margin({ left: 16 })
          }
        }, (it: InfoRow) => it.key)
      }
      .width('92%')
      .backgroundColor($r('app.color.bg_card')).borderRadius(16)
      .alignSelf(ItemAlign.Center)
    }
    .width('100%')
  }

  @Builder logoutDialog() {
    ConfirmDialog({
      message: '确定要退出登录吗？',
      danger: true,
      onConfirm: () => { this.logoutShow = false; userStore.logout() },
      onCancel: () => { this.logoutShow = false }
    })
  }

  build() {
    Column() {
      this.BlueTopHeader()

      // 3 张入口卡
      ForEach(this.entries, (it: EntryRow) => {
        this.EntryCard(it)
      }, (it: EntryRow) => it.key)

      this.InfoGroup()

      // 退出登录（红色大圆角按钮，白边红字，参考图同款）
      Button('退出登录', { type: ButtonType.Normal })
        .width('90%').height(60)
        .margin({ top: 36, bottom: 30 })
        .backgroundColor($r('app.color.danger_light'))
        .fontColor($r('app.color.danger'))
        .fontSize(22).fontWeight(600)
        .borderRadius($r('app.float.radius_lg'))
        .onClick(() => { this.logoutShow = true })
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .bindSheet($$this.logoutShow, this.logoutDialog(), { height: 300, preferType: SheetType.CENTER, showClose: false, dragBar: true, backgroundColor: Color.White })
  }
}
