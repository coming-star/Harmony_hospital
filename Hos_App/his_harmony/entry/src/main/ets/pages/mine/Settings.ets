/**
 * 【设置页】交付负责人：成员 D。
 * Grouped List 风格：通用 / 关于 / 账号
 */
import userStore from '../../store/UserStore.ets'
import { ConfirmDialog } from '../../components/ConfirmDialog.ets'
import { AppBar } from '../../components/AppBar.ets'
import { promptAction } from '@kit.ArkUI'

interface RowItem {
  key: string
  label: string
  group: 'general' | 'about' | 'account'
  desc?: string
  danger?: boolean
  onClick?: () => void
}

@Entry
@Component
struct Settings {
  @State logoutShow = false

  private rows: RowItem[] = [
    { key:'cache',   label:'清除缓存',      group:'general', desc:'12.3 MB', onClick:() => promptAction.showToast({message:'缓存已清除'}) },
    { key:'update',  label:'检查更新',      group:'general', desc:'已经是最新版本 v1.0.0' },
    { key:'about',   label:'关于我们',      group:'about',   desc:'东软 his 挂号系统 v1.0.0' },
    { key:'contact', label:'联系客服',      group:'about',   desc:'400-000-0000' },
    { key:'logout',  label:'退出登录',      group:'account', danger:true }
  ]
  private groups: Array<{key: string, label: string}> = [
    { key:'general', label:'通用' },
    { key:'about',   label:'关于' },
    { key:'account', label:'账号' }
  ]

  clickRow(r: RowItem) {
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
        const items = this.rows.filter(r => r.group === gKey)
        ForEach(items, (r: RowItem, idx: number) => {
          this.Row(r)
          if (idx < items.length - 1) {
            Divider().color($r('app.color.divider')).margin({left:16})
          }
        })
      }.width('92%').backgroundColor($r('app.color.bg_card')).borderRadius(16)
       .alignSelf(ItemAlign.Center)
    }.width('100%')
  }

  build() {
    Column() {
      AppBar({ title: '设置' })
      ForEach(this.groups, g => this.GroupCard(g.key, g.label))
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
    .bindSheet($$$this.logoutShow,
      ConfirmDialog({
        show: $$$this.logoutShow,
        message: '确定要退出登录吗？',
        danger: true,
        onConfirm: () => { userStore.logout() }
      }), { height: 280, preferType: SheetType.CENTER, showClose: false, dragBar: true })
  }
}
