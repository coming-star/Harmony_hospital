/**
 * 【选择科室】参考图第二张：
 * 顶部 AppBar "选择科室" → 下方灰底圆角搜索框「搜索科室」
 * → 一列 8 行大卡片：听诊器图标+科室名+简介+右侧 › 箭头（替代之前双栏）
 */
import { AppBar } from '../../components/AppBar'
import type { DepartmentTreeNode } from '../../types'
import * as deptApi from '../../api/department'
import { EmptyState } from '../../components/EmptyState'
import router from '@ohos.router'
import { Route } from '../../utils/theme'

@Entry
@Component
struct DepartmentSelect {
  @State search: string = ''
  @State tree: DepartmentTreeNode[] = []
  async aboutToAppear(): Promise<void> {
    try { this.tree = await deptApi.getDepartmentTree() } catch(_: Error) {}
  }

  /** 全部二级科室扁平化，支持按名称模糊搜索 */
  private flatSecondLevel(): DepartmentTreeNode[] {
    const key: string = this.search.trim()
    const arr: DepartmentTreeNode[] = []
    this.tree.forEach((p: DepartmentTreeNode) => {
      const kids: DepartmentTreeNode[] = p.children ?? []
      kids.forEach((s: DepartmentTreeNode) => {
        if (!key || s.name.includes(key) || (s.description && s.description.includes(key))) arr.push(s)
      })
    })
    return arr
  }

  build() {
    Column() {
      AppBar({ title:'选择科室' })

      // 搜索框
      Row() {
        Text('🔍').fontSize(18).fontColor($r('app.color.text_hint')).margin({ left: 14, right: 8 })
        TextInput({ placeholder:'搜索科室', text: this.search })
          .backgroundColor(Color.Transparent)
          .layoutWeight(1).height(44)
          .placeholderColor($r('app.color.text_hint'))
          .onChange(v => this.search = v)
      }
      .width('92%').height(52)
      .backgroundColor($r('app.color.input_bg'))
      .borderRadius(999)
      .margin({ top: 16, bottom: 16, left: 16, right: 16 })

      if (this.flatSecondLevel().length === 0) {
        EmptyState({ hint:'暂无匹配科室', emoji:'🏥' })
      } else {
        List() {
          ForEach(this.flatSecondLevel(), (s: DepartmentTreeNode) => {
            ListItem() {
              Column() {
                Row() {
                  Stack() {
                    Stack() { Blank() }.width(52).height(52).borderRadius(14).backgroundColor($r('app.color.primary_light'))
                    Text('🩺').fontSize(24)
                  }.margin({ right: 14 })
                  Column() {
                    Text(s.name).fontSize(17).fontWeight(700).fontColor($r('app.color.text_primary'))
                    if (s.description) {
                      Text(s.description).fontSize(12).fontColor($r('app.color.text_secondary'))
                        .margin({ top: 4 }).maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  Text('›').fontSize(28).fontColor($r('app.color.text_hint'))
                }.width('92%').padding(18).alignSelf(ItemAlign.Center)
              }
              .width('100%')
              .backgroundColor($r('app.color.bg_card')).borderRadius(16)
              .margin({bottom:12})
              .onClick(() => {
                router.pushUrl({ url: Route.DOCTOR_LIST, params: { departmentId: s.id } })
              })
            }.width('100%')
          }, s => String(s.id))
        }.layoutWeight(1).width('100%').padding({ left: 16, right: 16 })
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
