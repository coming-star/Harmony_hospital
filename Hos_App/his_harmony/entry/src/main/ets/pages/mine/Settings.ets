/**
 * 【设置页】交付负责人：成员 D。
 * Grouped List 风格：通用 / 关于 / 账号
 */
import userStore from '../../store/UserStore'
import { ConfirmDialog } from '../../components/ConfirmDialog'
import { AppBar } from '../../components/AppBar'
import { promptAction } from '@kit.ArkUI'

interface RowItem {
  key: string
  label: string
  group: 'general' | 'about' | 'account'
  desc?: string
  danger?: boolean
  onClick?: () => void
}

interface GroupItem {
  key: string
  label: string
}

@Entry
@Component
struct Settings {
  @State logoutShow: boolean = false

  private rows: RowItem[] = [
    { key:'cache',   label:'清除缓存',      group:'general', desc:'12.3 MB', onClick:() => promptAction.showToast({message:'缓存已清除'}) },
    { key:'update',  label:'检查更新',      group:'general', desc:'已经是最新版本 v1.0.0' },
    { key:'about',   label:'关于我们',      group:'about',   desc:'东软 his 挂号系统 v1.0.0' },
    { key:'contact', label:'联系客服',      group:'about',   desc:'400-000-0000' },
    { key:'logout',  label:'退出登录',      group:'account', danger:true }
  ]
  private groups: GroupItem[] = [
    { key:'general', label:'通用' },
    { key:'about',   label:'关于' },
    { key:'account', label:'账号' }
  ]

  clickRow(r: RowItem): void {
    if (r.key === 'logout') { this.logoutShow = true; return }
    if (r.onClick) r.onClick()
  }

  @Builder Row(r: RowItem) {
    Row() {
      Text(r.label)
        .fontSize(15)
        .fontColor(r.danger ? $r('app.color.danger') : $r('app.color.text_primary'))
        .layoutWeight(1)
      if (r.desc) {
        Text(r.desc).fontSize(12).fontColor($r('app.color.text_hint')).margin({right:8})
      }
      Text('›').fontSize(22).fontColor($r('app.color.text_hint'))
    }
    .width('100%').height(54).padding({left:16,right:16})
    .onClick(() => this.clickRow(r))
  }
  @Builder GroupCard(gKey: string, gLabel: string) {
    Column() {
      Text(gLabel).fontSize(12).fontColor($r('app.color.text_hint'))
        .width('100%').margin({left:16,bottom:4,top:12})
      Column() {
        ForEach(this.rows.filter(r => r.group === gKey), (r: RowItem, idx: number) => {
          this.Row(r)
          if (idx < (this.rows.filter(r2 => r2.group === gKey).length - 1)) {
            Divider().color($r('app.color.divider')).margin({left:16})
          }
        })
      }.width('92%').backgroundColor($r('app.color.bg_card')).borderRadius(16)
       .alignSelf(ItemAlign.Center)
    }.width('100%')
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
      AppBar({ title: '设置' })
      ForEach(this.groups, (g: GroupItem) => this.GroupCard(g.key, g.label))
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
    .bindSheet($$this.logoutShow, this.logoutDialog(), { height: 280, preferType: SheetType.CENTER, showClose: false, dragBar: true })
  }
}
