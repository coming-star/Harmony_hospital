/**
 * 【就诊人选择】交付负责人：成员 C
 * 入参：slotId（必填）
 * 逻辑：单选一个就诊人 → 去订单确认；没有就诊人 → 新增弹表单
 */
import router from '@ohos.router'
import type { PatientContact, ContactRequest, RelationOption, Relation } from '../../types'
import * as contactApi from '../../api/contact'
import { AvatarIcon } from '../../components/AvatarIcon'
import { AppBar } from '../../components/AppBar'
import { PrimaryButton } from '../../components/PrimaryButton'
import { Route } from '../../utils/theme'
import { RelationValue, relationText } from '../../types'
import { RelationList } from '../../types'
import { showToast } from '../../utils/toast'

@Entry
@Component
struct ContactSelect {
  /** 雪花大整数 ID 按字符串传递，禁止 Number() 转换（会丢精度） */
  @State slotId: string = ''
  @State doctorName: string = ''
  @State levelName: string = ''
  @State feeFen: number = 0
  @State visitDate: string = ''
  @State startTime: string = ''
  @State endTime: string = ''
  @State list: PatientContact[] = []
  @State selectedId: string = ''
  @State addSheet: boolean = false
  @State addName: string = ''
  @State addPhone: string = ''
  @State addIdCard: string = ''
  @State addRelation: Relation = RelationValue.SELF

  async aboutToAppear(): Promise<void> {
    const p: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined
    if (p) {
      if (p['slotId']) this.slotId = String(p['slotId'])
      this.doctorName = String(p['doctorName'] ?? '')
      this.levelName = String(p['levelName'] ?? '')
      this.feeFen = Number(p['feeFen'] ?? 0)
      this.visitDate = String(p['visitDate'] ?? '')
      this.startTime = String(p['startTime'] ?? '')
      this.endTime = String(p['endTime'] ?? '')
    }
    await this.load()
  }
  private async load(): Promise<void> {
    try { this.list = await contactApi.listContacts() } catch (_) {}
  }
  private goConfirm(): void {
    if (!this.selectedId) { showToast('请选择就诊人'); return }
    router.pushUrl({ url: Route.ORDER_CONFIRM, params: {
      slotId: this.slotId,
      doctorName: this.doctorName,
      levelName: this.levelName,
      feeFen: this.feeFen,
      visitDate: this.visitDate,
      startTime: this.startTime,
      endTime: this.endTime,
      contactId: this.selectedId
    } })
  }
  private async submitAdd(): Promise<void> {
    if (!this.addName.trim()) { showToast('请输入姓名'); return }
    if (!/^1\d{10}$/.test(this.addPhone)) { showToast('手机号格式错误'); return }
    const idCard: string = this.addIdCard.trim()
    if (idCard.length > 0 && !/^\d{17}[\dXx]$/.test(idCard)) {
      showToast('身份证号格式错误（应为 18 位）'); return
    }
    const body: ContactRequest = { name: this.addName, phone: this.addPhone, relation: this.addRelation }
    if (idCard.length > 0) { body.idCard = idCard }
    try {
      const r = await contactApi.createContact(body)
      this.addSheet = false
      this.addName = ''; this.addPhone = ''; this.addIdCard = ''
      await this.load()
      this.selectedId = r.contactId
    } catch (_) {}
  }

  @Builder AddContactSheet() {
    Column() {
      Text('新增就诊人').fontSize(22).fontWeight(700).margin({top:16,bottom:12})
      TextInput({ placeholder: '姓名' }).width('86%').height(56).fontSize(30).margin({bottom:12})
        .onChange(v => this.addName = v)
      TextInput({ placeholder: '手机号' }).width('86%').height(56).fontSize(30).margin({bottom:12})
        .type(InputType.PhoneNumber).onChange(v => this.addPhone = v)
      TextInput({ placeholder: '身份证号（选填）' }).width('86%').height(56).fontSize(30).margin({bottom:12})
        .onChange(v => this.addIdCard = v).maxLength(18)
      // 关系单选（简化 5 个 Chip）
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(RelationList, (r: RelationOption) => {
          Text(r.label)
            .fontSize(20)
            .padding({left:18,right:18,top:10,bottom:10})
            .margin(6)
            .borderRadius(999)
            .backgroundColor(this.addRelation === r.key ? $r('app.color.primary_light') : $r('app.color.bg_page'))
            .fontColor(this.addRelation === r.key ? $r('app.color.primary') : $r('app.color.text_primary'))
            .borderWidth(1).borderColor(this.addRelation===r.key ? $r('app.color.primary') : $r('app.color.divider'))
            .onClick(() => { this.addRelation = r.key })
        })
      }.width('86%')

      Button('保存').width('86%').height(54).fontSize(25).margin({top:20,bottom:24})
        .backgroundColor($r('app.color.primary'))
        .onClick(() => this.submitAdd())
    }.width('100%').alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      AppBar({ title: '就诊人' })
      List() {
        ForEach(this.list, (c: PatientContact) => {
          ListItem() {
            Row() {
              Radio({ value: 'c_'+c.id, group: 'contacts' })
                .checked(this.selectedId === c.id)
                .onChange(() => { this.selectedId = c.id })
              AvatarIcon({ name: c.name, iconSize: 52 }).margin({ left: 12 })
              Column() {
                Row() {
                  Text(c.name).fontSize(27).fontWeight(600).margin({right:12})
                  Text(relationText(c.relation)).fontSize(23)
                    .padding({left:12,right:12,top:6,bottom:6})
                    .backgroundColor($r('app.color.primary_light'))
                    .fontColor($r('app.color.primary'))
                    .borderRadius(999)
                }
                Text(c.phone).fontSize(24).fontColor($r('app.color.text_hint')).margin({top:8})
                if (c.idCardMasked && c.idCardMasked.length > 0) {
                  Text(`身份证 ${c.idCardMasked}`).fontSize(22).fontColor($r('app.color.text_hint')).margin({top:4})
                }
              }.margin({ left: 18 }).layoutWeight(1).alignItems(HorizontalAlign.Start)
            }
            .width('100%').padding(20)
            .onClick(() => { this.selectedId = c.id })
          }
          .borderWidth({bottom:0.5}).borderColor($r('app.color.divider'))
          .width('92%').alignSelf(ItemAlign.Center)
        }, (c: PatientContact) => String(c.id))
      }.layoutWeight(1).width('100%').margin({top:12})

      Row() {
        PrimaryButton({
          label:'新增就诊人', variant:'light', onTap: () => { this.addSheet = true }
        }).width('45%').margin({right:12})
        PrimaryButton({
          label:'下一步', variant:'primary', onTap: () => this.goConfirm()
        }).width('45%')
      }.padding(16)
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
    .bindSheet($$this.addSheet, this.AddContactSheet(),
      { height: 580, showClose: true, dragBar: true })
  }
}
