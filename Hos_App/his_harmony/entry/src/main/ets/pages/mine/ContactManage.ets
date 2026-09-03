/**
 * 【就诊人管理】交付负责人：成员 D。
 * 列表 + 编辑图标 + 删除图标 + 右下角 FAB 新增。
 */
import type { PatientContact, ContactRequest, Relation, RelationText, RelationList } from '../../types'
import * as contactApi from '../../api/contact.ets'
import { AvatarIcon } from '../../components/AvatarIcon.ets'
import { EmptyState } from '../../components/EmptyState.ets'
import { ConfirmDialog } from '../../components/ConfirmDialog.ets'
import { AppBar } from '../../components/AppBar.ets'
import { PrimaryButton } from '../../components/PrimaryButton.ets'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct ContactManage {
  @State list: PatientContact[] = []
  @State loading = true
  @State addSheet = false
  @State editId: number = 0
  @State fName = ''
  @State fPhone = ''
  @State fRelation: Relation = Relation.SELF
  @State deleteShow = false
  @State deleteTarget?: PatientContact
  @State deleteLoading = false

  async aboutToAppear() { await this.reload() }

  async reload() {
    this.loading = true
    try { this.list = await contactApi.listContacts() } catch(_) {}
    finally { this.loading = false }
  }

  openAdd() {
    this.editId = 0
    this.fName = ''; this.fPhone = ''; this.fRelation = Relation.SELF
    this.addSheet = true
  }
  openEdit(c: PatientContact) {
    this.editId = c.id
    this.fName = c.name; this.fPhone = c.phone; this.fRelation = c.relation
    this.addSheet = true
  }
  async submitForm() {
    if (!this.fName.trim()) return promptAction.showToast({message:'请输入姓名'})
    if (!/^1\d{10}$/.test(this.fPhone)) return promptAction.showToast({message:'手机号格式错误'})
    const body: ContactRequest = { name: this.fName.trim(), phone: this.fPhone, relation: this.fRelation }
    try {
      if (this.editId) await contactApi.updateContact(this.editId, body)
      else           await contactApi.createContact(body)
      this.addSheet = false
      await this.reload()
    } catch(_) {}
  }
  askDelete(c: PatientContact) { this.deleteTarget = c; this.deleteShow = true }
  async confirmDelete() {
    if (!this.deleteTarget || this.deleteLoading) return
    this.deleteLoading = true
    try {
      await contactApi.deleteContact(this.deleteTarget.id)
      this.deleteShow = false
      await this.reload()
    } catch(_) {}
    finally { this.deleteLoading = false }
  }

  build() {
    Column() { AppBar({ title:'就诊人' }) }
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.loading) {
        Column() { Text('加载中…').fontColor($r('app.color.text_hint')) }
          .width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else if (this.list.length === 0) {
        Column().width('100%').height('100%').padding({ top: 60 }) {
          EmptyState({
            hint: '还没有就诊人，点击下方按钮添加', emoji:'👨‍👩‍👧',
            actionText: '新增就诊人', onAction: () => this.openAdd()
          })
        }
      } else {
        List() {
          ForEach(this.list, (c: PatientContact) => {
            ListItem() {
              Row() {
                AvatarIcon({ name: c.name, size: 48 })
                Column().alignItems(HorizontalAlign.Start).layoutWeight(1).margin({left:12}) {
                  Row() {
                    Text(c.name).fontSize(15).fontWeight(600).fontColor($r('app.color.text_primary')).margin({right:8})
                    Text(RelationText[c.relation] ?? '')
                      .fontSize(11).padding({left:8,right:8,top:2,bottom:2})
                      .backgroundColor($r('app.color.primary_light'))
                      .fontColor($r('app.color.primary')).borderRadius(999)
                  }
                  Text(c.phone).fontSize(12).fontColor($r('app.color.text_hint')).margin({top:4})
                }
                // 编辑 / 删除
                Text('✎').fontSize(18).fontColor($r('app.color.secondary_booking'))
                  .padding(12).onClick(() => this.openEdit(c))
                Text('🗑').fontSize(18).fontColor($r('app.color.danger'))
                  .padding(12).onClick(() => this.askDelete(c))
              }.width('92%').padding(16).alignSelf(ItemAlign.Center)
               .backgroundColor($r('app.color.bg_card')).borderRadius(16)
               .margin({ top: 12 })
            }.width('100%')
          }, c => String(c.id))
        }.width('100%').padding({top:4,bottom:96})
      }

      // FAB
      Column() {
        Text('+').fontSize(36).fontColor(Color.White)
          .width(56).height(56).textAlign(TextAlign.Center)
      }
      .position({x: '82%', y: '82%'})
      .width(56).height(56)
      .backgroundColor($r('app.color.primary'))
      .borderRadius(28)
      .shadow({radius:8,color:'#440FA99E'})
      .onClick(() => this.openAdd())
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
    .bindSheet($$$this.addSheet, this.FormSheet(), { height: 560, showClose: true, dragBar: true })
    .bindSheet($$$this.deleteShow,
      ConfirmDialog({
        show: $$$this.deleteShow,
        title: '删除就诊人',
        message: this.deleteTarget ? `确认删除就诊人「${this.deleteTarget.name}」？若该就诊人存在未终态订单将无法删除。` : '确认删除该就诊人？',
        danger: true, confirmText: '删除',
        onConfirm: () => this.confirmDelete()
      }), { height: 280, preferType: SheetType.CENTER, showClose: false, dragBar: true })
  }

  @Builder FormSheet() {
    Column() {
      Text(this.editId ? '编辑就诊人' : '新增就诊人').fontSize(18).fontWeight(700).margin({top:16,bottom:12})
      TextInput({ placeholder: '姓名', text: this.fName }).width('86%').height(46)
        .backgroundColor($r('app.color.bg_page')).borderRadius(12).margin({bottom:12})
        .onChange(v => this.fName = v)
      TextInput({ placeholder: '手机号', text: this.fPhone }).type(InputType.PhoneNumber)
        .width('86%').height(46).backgroundColor($r('app.color.bg_page'))
        .borderRadius(12).margin({bottom:12}).onChange(v => this.fPhone = v)
      Text('关系').fontSize(13).fontColor($r('app.color.text_hint'))
        .width('86%').margin({bottom:6}).alignSelf(ItemAlign.Start)
      Flex({wrap: FlexWrap.Wrap}) {
        ForEach(RelationList, r => {
          Text(r.label)
            .fontSize(13)
            .padding({left:14,right:14,top:6,bottom:6}).margin(6)
            .borderRadius(999)
            .backgroundColor(this.fRelation===r.key ? $r('app.color.primary_light') : $r('app.color.bg_page'))
            .fontColor(this.fRelation===r.key ? $r('app.color.primary') : $r('app.color.text_primary'))
            .borderWidth(1).borderColor(this.fRelation===r.key ? $r('app.color.primary') : $r('app.color.divider'))
            .onClick(() => { this.fRelation = r.key })
        })
      }.width('86%').justifyContent(FlexAlign.Start)
      PrimaryButton({ label:'保存', variant:'primary', onClick: () => this.submitForm() })
        .width('86%').margin({top:24,bottom:24})
    }.width('100%').alignItems(HorizontalAlign.Center).backgroundColor(Color.White)
  }
}
