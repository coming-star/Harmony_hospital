/**
 * 【就诊人管理】交付负责人：成员 D。
 * 列表 + 编辑图标 + 删除图标 + 右下角 FAB 新增。
 */
import type { PatientContact, ContactRequest, RelationOption, Relation } from '../../types'
import { RelationValue, RelationList, relationText } from '../../types'
import * as contactApi from '../../api/contact'
import { AppIcon } from '../../utils/icons'
import { AvatarIcon } from '../../components/AvatarIcon'
import { EmptyState } from '../../components/EmptyState'
import { ConfirmDialog } from '../../components/ConfirmDialog'
import { AppBar } from '../../components/AppBar'
import { PrimaryButton } from '../../components/PrimaryButton'
import { showToast } from '../../utils/toast'

@Entry
@Component
struct ContactManage {
  @State list: PatientContact[] = []
  @State loading: boolean = true
  @State addSheet: boolean = false
  /** 正在编辑的就诊人 ID（字符串，防精度丢失；空串=新增模式） */
  @State editId: string = ''
  @State fName: string = ''
  @State fPhone: string = ''
  @State fIdCard: string = ''
  @State fRelation: Relation = RelationValue.SELF
  @State deleteShow: boolean = false
  @State deleteTarget: PatientContact | undefined = undefined
  @State deleteLoading: boolean = false

  async aboutToAppear(): Promise<void> { await this.reload() }

  async reload(): Promise<void> {
    this.loading = true
    try { this.list = await contactApi.listContacts() } catch (_) {}
    finally { this.loading = false }
  }

  openAdd(): void {
    this.editId = ''
    this.fName = ''; this.fPhone = ''; this.fIdCard = ''; this.fRelation = RelationValue.SELF
    this.addSheet = true
  }
  openEdit(c: PatientContact): void {
    this.editId = c.id
    // 编辑时身份证字段留空（后端不回显明文）；留空即保留原值，重新输入则覆盖
    this.fName = c.name; this.fPhone = c.phone; this.fIdCard = ''; this.fRelation = c.relation
    this.addSheet = true
  }
  async submitForm(): Promise<void> {
    if (!this.fName.trim()) { showToast('请输入姓名'); return }
    if (!/^1\d{10}$/.test(this.fPhone)) { showToast('手机号格式错误'); return }
    const idCard: string = this.fIdCard.trim()
    if (idCard.length > 0 && !/^\d{17}[\dXx]$/.test(idCard)) {
      showToast('身份证号格式错误（应为 18 位）'); return
    }
    const body: ContactRequest = { name: this.fName.trim(), phone: this.fPhone, relation: this.fRelation }
    // 非空才传：新增时空=不采集；编辑时空=保留原值
    if (idCard.length > 0) { body.idCard = idCard }
    try {
      if (this.editId) await contactApi.updateContact(this.editId, body)
      else           await contactApi.createContact(body)
      this.addSheet = false
      await this.reload()
    } catch (_) {}
  }
  askDelete(c: PatientContact): void { this.deleteTarget = c; this.deleteShow = true }
  async confirmDelete(): Promise<void> {
    if (!this.deleteTarget || this.deleteLoading) return
    this.deleteLoading = true
    try {
      await contactApi.deleteContact(this.deleteTarget.id)
      this.deleteShow = false
      await this.reload()
    } catch (_) {}
    finally { this.deleteLoading = false }
  }

  @Builder deleteDialog() {
    ConfirmDialog({
      title: '删除就诊人',
      message: this.deleteTarget ? `确认删除就诊人「${this.deleteTarget.name}」？若该就诊人存在未终态订单将无法删除。` : '确认删除该就诊人？',
      danger: true,
      confirmText: '删除',
      onConfirm: () => this.confirmDelete(),
      onCancel: () => { this.deleteShow = false }
    })
  }

  build() {
    Stack() {
      Column() {
        AppBar({ title:'就诊人' })
        Stack({ alignContent: Alignment.TopStart }) {
          if (this.loading) {
            Column() { Text('加载中…').fontSize(20).fontColor($r('app.color.text_hint')) }
              .width('100%').height('100%').justifyContent(FlexAlign.Center)
          } else if (this.list.length === 0) {
            Column() {
              EmptyState({
                hint: '还没有就诊人，点击下方按钮添加', icon: AppIcon.profileOutline,
                actionText: '新增就诊人', onAction: () => this.openAdd()
              })
            }.width('100%').height('100%').padding({ top: 60 })
          } else {
            List() {
              ForEach(this.list, (c: PatientContact) => {
                ListItem() {
                  Row() {
                    AvatarIcon({ name: c.name, iconSize: 56 })
                    Column() {
                      Row() {
                        Text(c.name).fontSize(27).fontWeight(600).fontColor($r('app.color.text_primary')).margin({right:12})
                        Text(relationText(c.relation))
                          .fontSize(23).padding({left:12,right:12,top:6,bottom:6})
                          .backgroundColor($r('app.color.primary_light'))
                          .fontColor($r('app.color.primary')).borderRadius(999)
                      }
                      Text(c.phone).fontSize(24).fontColor($r('app.color.text_hint')).margin({top:8})
                      if (c.idCardMasked && c.idCardMasked.length > 0) {
                        Text(`身份证 ${c.idCardMasked}`).fontSize(22).fontColor($r('app.color.text_hint')).margin({top:4})
                      }
                    }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({left:16})
                    SymbolGlyph($r(AppIcon.edit)).fontSize(30).padding(12)
                      .onClick(() => this.openEdit(c))
                    SymbolGlyph($r(AppIcon.delete)).fontSize(30).padding(12)
                      .onClick(() => this.askDelete(c))
                  }.width('92%').padding(20).alignSelf(ItemAlign.Center)
                   .backgroundColor($r('app.color.bg_card')).borderRadius(16).margin({ top: 12 })
                }.width('100%')
              }, (c: PatientContact) => String(c.id))
            }.width('100%').padding({top:4,bottom:96})
          }
        }.width('100%').layoutWeight(1)
      }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))

      Text('+').fontSize(40).fontWeight(700).fontColor(Color.White)
        .position({ x: '84%', y: '82%' })
        .width(60).height(60).textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.primary'))
        .borderRadius(30)
        .shadow({radius:8,color:'#440FA99E'})
        .onClick(() => this.openAdd())
      // 删除确认：全屏遮罩 + ConfirmDialog（纯条件渲染）。
      // 不再用第二个 bindSheet —— 同页挂多个 bindSheet 会相互覆盖导致弹窗失效；
      // 且遮罩底色统一，顺带解决之前弹窗中间白色/两侧灰色不一致的问题。
      if (this.deleteShow) {
        Column() {
          this.deleteDialog()
        }
        .width('100%').height('100%')
        .backgroundColor('#66000000')
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.deleteShow = false })
      }
    }
    .width('100%').height('100%')
    // 页面根节点只挂这一个 bindSheet —— 与 ContactSelect 页「新增就诊人」弹窗完全相同的写法
    .bindSheet($$this.addSheet, this.FormSheet(), { height: 620, showClose: true, dragBar: true })
  }

  @Builder FormSheet() {
    Column() {
      Text(this.editId ? '编辑就诊人' : '新增就诊人').fontSize(22).fontWeight(700).margin({top:16,bottom:12})
      TextInput({ placeholder: '姓名', text: this.fName }).width('86%').height(56)
        .backgroundColor($r('app.color.bg_page')).borderRadius(12).margin({bottom:12})
        .onChange(v => this.fName = v)
      TextInput({ placeholder: '手机号', text: this.fPhone }).type(InputType.PhoneNumber)
        .width('86%').height(56).backgroundColor($r('app.color.bg_page'))
        .borderRadius(12).margin({bottom:12}).onChange(v => this.fPhone = v)
      TextInput({ placeholder: this.editId ? '身份证号（留空则不修改）' : '身份证号（选填）', text: this.fIdCard })
        .width('86%').height(56).backgroundColor($r('app.color.bg_page'))
        .borderRadius(12).margin({bottom:12}).onChange(v => this.fIdCard = v)
        .maxLength(18)
      Flex({wrap: FlexWrap.Wrap}) {
        ForEach(RelationList, (r: RelationOption) => {
          Text(r.label)
            .fontSize(19)
            .padding({left:14,right:14,top:6,bottom:6}).margin(6)
            .borderRadius(999)
            .backgroundColor(this.fRelation===r.key ? $r('app.color.primary_light') : $r('app.color.bg_page'))
            .fontColor(this.fRelation===r.key ? $r('app.color.primary') : $r('app.color.text_primary'))
            .borderWidth(1).borderColor(this.fRelation===r.key ? $r('app.color.primary') : $r('app.color.divider'))
            .onClick(() => { this.fRelation = r.key })
        })
      }.width('86%')
      PrimaryButton({ label:'保存', variant:'primary', onTap: () => this.submitForm() })
        .width('86%').margin({top:24,bottom:24})
    }.width('100%').alignItems(HorizontalAlign.Center).backgroundColor($r('app.color.sheet_bg'))
  }
}
