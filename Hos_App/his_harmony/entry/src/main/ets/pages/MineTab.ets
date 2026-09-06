/**
 * 【我的 Tab】美化版：
 * 1. 渐变蓝色顶部 + 半透明装饰圆 + 白边头像 + 会员标签
 * 2. 悬浮统计数据栏（挂号次数 / 就诊人数 / 收藏医生）
 * 3. 我的服务卡片：彩色圆形图标 + 标题 + 副标题 + 箭头
 * 4. 更多功能：帮助中心 / 意见反馈 / 关于我们
 * 5. 精致系统信息 + 退出登录按钮
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
  iconBg: ResourceColor
  disabled?: boolean
}
interface InfoRow {
  key: string
  value: string
}
interface StatItem {
  key: string
  value: string
  label: string
}

@Component
export struct MineTab {
  @State logoutShow: boolean = false
  @State nickname: string = ''
  @State phone: string = ''

  private readonly stats: StatItem[] = [
    { key: 'orders', value: '12', label: '挂号次数' },
    { key: 'contacts', value: '3', label: '就诊人数' },
    { key: 'favorites', value: '5', label: '收藏医生' }
  ]

  private readonly serviceEntries: EntryRow[] = [
    { key:'orders',   icon: AppIcon.message, title:'挂号记录', sub:'查看历史挂号', route: Route.ORDER_RECORD, iconBg: $r('app.color.primary') },
    { key:'contacts', icon: AppIcon.profileOutline, title:'就诊人管理', sub:'管理绑定就诊人', route: Route.CONTACT_MGNT, iconBg: $r('app.color.success') },
    { key:'settings', icon: AppIcon.settings, title:'设置', sub:'通用 · 关于 · 退出', route: Route.SETTINGS, iconBg: $r('app.color.warning') }
  ]

  private readonly moreEntries: EntryRow[] = [
    { key:'help',     icon: AppIcon.lightbulb, title:'帮助中心', sub:'常见问题解答', iconBg: $r('app.color.secondary_ai') },
    { key:'feedback', icon: AppIcon.message, title:'意见反馈', sub:'告诉我们您的建议', iconBg: $r('app.color.danger') },
    { key:'about',    icon: AppIcon.profileOutline, title:'关于我们', sub:'版本信息 · 隐私政策', iconBg: $r('app.color.primary') }
  ]

  private readonly systemInfos: InfoRow[] = [
    { key:'系统名称', value:'东软云医院预约挂号系统' },
    { key:'当前版本', value:'v1.0.0' },
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

  @Builder GradientHeader() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 渐变背景
      Column()
        .width('100%').height(220)
        .linearGradient({
          angle: 135,
          colors: [['#0A66C2', 0.0], ['#1565C0', 0.5], ['#1976D2', 1.0]]
        })

      // 装饰圆1（右上角大圆）
      Circle()
        .width(200).height(200)
        .opacity(0.08)
        .fill(Color.White)
        .position({ x: '65%', y: -60 })

      // 装饰圆2（左上角小圆）
      Circle()
        .width(120).height(120)
        .opacity(0.06)
        .fill(Color.White)
        .position({ x: -30, y: 40 })

      // 装饰圆3（右下角迷你圆）
      Circle()
        .width(60).height(60)
        .opacity(0.1)
        .fill(Color.White)
        .position({ x: '80%', y: 140 })

      // 用户信息区
      Row() {
        // 头像（白色边框 + 阴影）
        Stack() {
          Circle().width(82).height(82).fill(Color.White)
          AvatarIcon({ name: this.nickname || '健康用户', iconSize: 74, bg: $r('app.color.primary_light') })
        }

        Column() {
          Row() {
            Text(this.nickname ? this.nickname : '健康用户')
              .fontSize(26).fontWeight(FontWeight.Bold).fontColor(Color.White)
            // 会员标签
            Row() {
              SymbolGlyph($r(AppIcon.lightbulb))
                .fontSize(14).fontColor(['#FFD700'])
              Text('健康会员')
                .fontSize(12).fontColor('#FFD700').fontWeight(FontWeight.Medium)
            }
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor('rgba(255,215,0,0.15)')
            .borderRadius(20)
            .margin({ left: 10 })
          }

          if (userStore.isLoggedIn()) {
            Text(this.phone ? `手机号 ${Format.maskPhone(this.phone)}` : '')
              .fontSize(16).fontColor('rgba(255,255,255,0.8)').margin({ top: 8 })
          } else {
            Text('未登录，点击登录')
              .fontSize(16).fontColor('rgba(255,255,255,0.9)')
              .margin({ top: 8 }).padding(4)
              .onClick(() => { try { router.pushUrl({ url: Route.LOGIN }) } catch (_) {} })
          }
        }.margin({ left: 16 }).layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('92%')
      .margin({ top: 60, left: 16, right: 16 })
      .alignSelf(ItemAlign.Start)
    }
    .width('100%').height(220)
  }

  @Builder StatsBar() {
    Row() {
      ForEach(this.stats, (item: StatItem, idx: number) => {
        Column() {
          Text(item.value)
            .fontSize(28).fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.primary'))
          Text(item.label)
            .fontSize(13).fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        if (idx < this.stats.length - 1) {
          Column()
            .width(0.5).height(36)
            .backgroundColor($r('app.color.divider'))
        }
      }, (item: StatItem) => item.key)
    }
    .width('92%')
    .padding({ top: 18, bottom: 18 })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 12, color: 'rgba(10,102,194,0.08)', offsetX: 0, offsetY: 4 })
    .margin({ top: -36 })
    .alignSelf(ItemAlign.Center)
    .zIndex(10)
  }

  @Builder SectionTitle(title: string) {
    Row() {
      Text(title)
        .fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Blank()
    }
    .width('92%')
    .margin({ top: 24, bottom: 12 })
    .alignSelf(ItemAlign.Center)
  }

  @Builder EntryCard(r: EntryRow) {
    Row() {
      // 彩色圆形图标
      Stack() {
        Circle().width(46).height(46).fill(r.iconBg).opacity(0.12)
        SymbolGlyph($r(r.icon))
          .fontSize(24)
          .fontColor([r.iconBg])
      }.margin({ right: 14 })

      Column() {
        Text(r.title).fontSize(17).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
        Text(r.sub).fontSize(13).fontColor($r('app.color.text_hint')).margin({ top: 4 })
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)

      SymbolGlyph($r(AppIcon.forward))
        .fontSize(20)
        .fontColor([$r('app.color.text_hint')])
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .onClick(() => this.click(r))
  }

  @Builder EntryGroup(entries: EntryRow[]) {
    Column() {
      ForEach(entries, (it: EntryRow, idx: number) => {
        this.EntryCard(it)
        if (idx < entries.length - 1) {
          Divider()
            .color($r('app.color.divider'))
            .margin({ left: 76, right: 16 })
            .strokeWidth(0.5)
        }
      }, (it: EntryRow) => it.key)
    }
    .width('92%')
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.04)', offsetX: 0, offsetY: 2 })
    .alignSelf(ItemAlign.Center)
  }

  @Builder InfoGroup() {
    Column() {
      Row() {
        Text('系统信息')
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
      }
      .width('100%')
      .margin({ bottom: 12 })

      Column() {
        ForEach(this.systemInfos, (it: InfoRow, idx: number) => {
          Row() {
            Text(it.key)
              .fontSize(14).fontColor($r('app.color.text_secondary'))
              .layoutWeight(1)
            Text(it.value)
              .fontSize(14).fontColor($r('app.color.text_primary'))
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })

          if (idx < this.systemInfos.length - 1) {
            Divider()
              .color($r('app.color.divider'))
              .margin({ left: 16 })
              .strokeWidth(0.5)
          }
        }, (it: InfoRow) => it.key)
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 10, color: 'rgba(0,0,0,0.04)', offsetX: 0, offsetY: 2 })
    }
    .width('92%')
    .margin({ top: 24 })
    .alignSelf(ItemAlign.Center)
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
      this.GradientHeader()
      this.StatsBar()

      this.SectionTitle('我的服务')
      this.EntryGroup(this.serviceEntries)

      this.SectionTitle('更多功能')
      this.EntryGroup(this.moreEntries)

      this.InfoGroup()

      // 退出登录按钮
      Button('退出登录', { type: ButtonType.Normal })
        .width('88%').height(52)
        .margin({ top: 32, bottom: 24 })
        .backgroundColor('rgba(219,58,47,0.08)')
        .fontColor($r('app.color.danger'))
        .fontSize(17).fontWeight(FontWeight.Medium)
        .borderRadius(14)
        .onClick(() => { this.logoutShow = true })
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .bindSheet($$this.logoutShow, this.logoutDialog(), { height: 300, preferType: SheetType.CENTER, showClose: false, dragBar: true, backgroundColor: Color.White })
  }
}
