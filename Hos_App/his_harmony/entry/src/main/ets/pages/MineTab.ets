/**
 * 【我的 Tab】完全匹配参考图右侧第 4 张：
 * 1. 蓝色顶部：圆形头像（首字母）+ 大号昵称 + 蓝色小字手机号（健康用户 / 186xxxx）
 * 2. 三张圆角白卡：挂号记录 / 就诊人管理 / AI管家设置（每张 方框图标+主文灰副文+右侧 › 箭头）
 * 3. 系统信息分组：系统名称 / 技术栈 键值对
 * 4. 红色"退出登录"按钮（弹 ConfirmDialog 二次确认）
 */
import router from '@ohos.router'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import userStore from '../store/UserStore'
import { AvatarIcon } from '../components/AvatarIcon'
import { ConfirmDialog } from '../components/ConfirmDialog'
import { AppIcon } from '../utils/icons'
import { Format } from '../utils/format'
import { Route } from '../utils/theme'
import { showToast } from '../utils/toast'
import * as uploadApi from '../api/upload'
import * as authApi from '../api/auth'
import * as messageApi from '../api/message'
import type { MeResponse, UpdateMeRequest } from '../types'

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
  @State avatarUrl: string = ''
  @State nickEditShow: boolean = false
  @State nickInput: string = ''
  @State uploading: boolean = false
  /** 站内信未读数（消息入口角标；Index 的 Tab 红点同源 AppStorage） */
  @StorageProp('unreadMsgCount') unreadMsgCount: number = 0
  private readonly entries: EntryRow[] = [
    { key:'orders',   icon: AppIcon.message, title:'挂号记录',     sub:'查看历史挂号',           route: Route.ORDER_RECORD },
    { key:'contacts', icon: AppIcon.profileOutline, title:'就诊人管理',   sub:'管理绑定就诊人',           route: Route.CONTACT_MGNT },
    { key:'settings', icon: AppIcon.settings, title:'设置',       sub:'通用 · 关于 · 退出登录',  route: Route.SETTINGS }
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
    this.avatarUrl = userStore.avatarUrl
    // 进入"我的"页顺带刷新未读数角标
    messageApi.refreshUnreadBadge()
  }

  /** 选择图片 → 上传头像 → 更新资料 */
  async pickAvatar(): Promise<void> {
    if (this.uploading) return
    try {
      const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      options.maxSelectNumber = 1
      const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker()
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(options)
      if (result.photoUris && result.photoUris.length > 0) {
        this.uploading = true
        const up = await uploadApi.uploadAvatar(result.photoUris[0])
        const me = await authApi.updateMe({ avatarUrl: up.url })
        await userStore.updateMe(me)
        this.avatarUrl = userStore.avatarUrl
        showToast('头像更新成功')
      }
    } catch (_) {
      // 用户取消选择不提示
    } finally {
      this.uploading = false
    }
  }

  openNickEdit(): void {
    this.nickInput = this.nickname
    this.nickEditShow = true
  }

  async saveNick(): Promise<void> {
    const nick: string = this.nickInput.trim()
    if (!nick) { showToast('昵称不能为空'); return }
    if (nick.length > 20) { showToast('昵称最长 20 字符'); return }
    try {
      const body: UpdateMeRequest = { nickname: nick }
      const me: MeResponse = await authApi.updateMe(body)
      await userStore.updateMe(me)
      this.nickname = userStore.nickname
      this.nickEditShow = false
      showToast('昵称修改成功')
    } catch (_) {}
  }

  @Builder BlueTopHeader() {
    Stack({alignContent:Alignment.Center}) {
      Column()
        .width('100%').height(180)
        .backgroundColor($r('app.color.primary'))

      Row() {
        // 头像：已登录可点击上传
        Stack({ alignContent: Alignment.BottomEnd }) {
          AvatarIcon({ name: this.nickname || '健康用户', url: this.avatarUrl, iconSize: 72, bg: $r('app.color.primary_light') })
          if (userStore.isLoggedIn()) {
            Circle()
              .width(26).height(26)
              .fill($r('app.color.text_white'))
              .margin({ right: -2, bottom: -2 })
            SymbolGlyph($r(AppIcon.camera))
              .fontSize(18)
              .fontColor([$r('app.color.primary')])
              .margin({ right: 0, bottom: 2 })
          }
        }
        .onClick(() => { if (userStore.isLoggedIn()) this.pickAvatar() })

        Column() {
          if (userStore.isLoggedIn()) {
            Row() {
              Text(this.nickname ? this.nickname : '健康用户')
                .fontSize(28).fontWeight(800).fontColor($r('app.color.text_white'))
              SymbolGlyph($r(AppIcon.edit))
                .fontSize(22).fontColor(['#CCFFFFFF']).margin({ left: 8 })
            }
            .onClick(() => this.openNickEdit())
          } else {
            Text('健康用户')
              .fontSize(28).fontWeight(800).fontColor($r('app.color.text_white'))
          }
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

  /** 消息中心入口卡：样式与 EntryCard 一致，右侧带未读数角标 */
  @Builder MessageEntryCard() {
    Row() {
      Stack() {
        Column().width(48).height(48).borderRadius(10).backgroundColor($r('app.color.primary_light'))
        SymbolGlyph($r(AppIcon.bell))
          .fontSize(30)
      }.margin({ right: 14 })

      Column() {
        Text('消息中心').fontSize(22).fontWeight(600).fontColor($r('app.color.text_primary'))
        Text('预约通知 · 就诊提醒').fontSize(18).fontColor($r('app.color.text_secondary')).margin({ top: 6 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)

      if (this.unreadMsgCount > 0) {
        Text(this.unreadMsgCount > 99 ? '99+' : String(this.unreadMsgCount))
          .fontSize(16).fontColor($r('app.color.text_white'))
          .backgroundColor($r('app.color.danger'))
          .borderRadius($r('app.float.radius_pill'))
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .margin({ right: 8 })
      }
      SymbolGlyph($r(AppIcon.forward))
        .fontSize(30)
    }
    .width('92%').padding(20).alignSelf(ItemAlign.Center)
    .backgroundColor($r('app.color.bg_card')).borderRadius(16)
    .margin({ top: 12 })
    .onClick(() => {
      if (!userStore.isLoggedIn()) {
        try { router.pushUrl({ url: Route.LOGIN }) } catch (_) {}
        return
      }
      try { router.pushUrl({ url: Route.MESSAGE_LIST }) } catch (_) {}
    })
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
    // 包一层撑满 sheet 的居中容器，修复弹窗内容偏上
    Column() {
      ConfirmDialog({
        message: '确定要退出登录吗？',
        danger: true,
        onConfirm: () => { this.logoutShow = false; userStore.logout() },
        onCancel: () => { this.logoutShow = false }
      })
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  @Builder nickEditMask() {
    Column() {
      Column() {
        Text('修改昵称').fontSize(22).fontWeight(700).margin({ top: 20, bottom: 16 })
        TextInput({ placeholder: '请输入昵称（1-20 字符）', text: this.nickInput })
          .width('80%').height(56)
          .backgroundColor($r('app.color.bg_page')).borderRadius(12)
          .maxLength(20)
          .onChange((v: string) => { this.nickInput = v })
        Row() {
          Button('取消')
            .width('38%').height(50).fontSize(20)
            .backgroundColor($r('app.color.bg_page')).fontColor($r('app.color.text_primary'))
            .borderRadius(12)
            .onClick(() => { this.nickEditShow = false })
          Button('保存')
            .width('38%').height(50).fontSize(20)
            .backgroundColor($r('app.color.primary')).fontColor(Color.White)
            .borderRadius(12).margin({ left: 16 })
            .onClick(() => this.saveNick())
        }.width('80%').margin({ top: 20, bottom: 20 })
      }
      .width('80%')
      .backgroundColor(Color.White).borderRadius(16)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.nickEditShow = false })
  }

  build() {
    Stack() {
      Column() {
        this.BlueTopHeader()

        // 消息中心入口（未读角标）
        this.MessageEntryCard()

        // 3 张入口卡
        ForEach(this.entries, (it: EntryRow) => {
          this.EntryCard(it)
        }, (it: EntryRow) => it.key)

        this.InfoGroup()

        // 退出登录（与设置页"账号"分组同款：浅色卡片行，红字居左，右侧 › 箭头）
        Row() {
          Text('退出登录')
            .fontSize(23)
            .fontColor($r('app.color.danger'))
            .layoutWeight(1)
          Text('›').fontSize(30).fontColor($r('app.color.text_hint'))
        }
        .width('92%').height(64).padding({ left: 20, right: 20 })
        .alignSelf(ItemAlign.Center)
        .backgroundColor($r('app.color.bg_card')).borderRadius(16)
        .margin({ top: 36, bottom: 30 })
        .onClick(() => { this.logoutShow = true })
      }
      .width('100%').height('100%')
      .backgroundColor($r('app.color.bg_page'))

      if (this.nickEditShow) {
        this.nickEditMask()
      }
    }
    .width('100%').height('100%')
    .bindSheet($$this.logoutShow, this.logoutDialog(), { height: 300, preferType: SheetType.CENTER, showClose: false, dragBar: true, backgroundColor: $r('app.color.sheet_bg') })
  }
}
