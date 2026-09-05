/**
 * 科室选择二级折叠菜单组件：一级科室卡片（可点击展开）→ 二级科室列表。
 * 用于 AppointmentTab 和 DepartmentSelect 页面，避免重复代码。
 *
 * - 搜索框：过滤一级科室（按名称/描述），或其下二级科室名称匹配
 * - 列表：每个一级科室一张卡片，展开时显示二级科室子列表
 * - 点击二级科室跳转到 DoctorList（选医生/时间）
 */
import router from '@ohos.router'
import { AppIcon } from '../utils/icons'
import { StethoscopeIcon } from './StethoscopeIcon'
import { Route } from '../utils/theme'
import type { DepartmentTreeNode } from '../types'
import * as deptApi from '../api/department'

@Component
export struct DepartmentAccordion {
  @State tree: DepartmentTreeNode[] = []
  @State search: string = ''
  @State expandedId: number = -1

  async aboutToAppear(): Promise<void> {
    try { this.tree = await deptApi.getDepartmentTree() } catch (_) {}
  }

  private getFilteredTree(): DepartmentTreeNode[] {
    const key = this.search.trim().toLowerCase()
    if (!key) return this.tree

    return this.tree.filter(level1 => {
      const l1Match = level1.name.toLowerCase().includes(key) ||
                      (level1.description?.toLowerCase().includes(key) ?? false)
      const l2Match = (level1.children ?? []).some(child =>
        child.name.toLowerCase().includes(key) ||
        (child.description?.toLowerCase().includes(key) ?? false)
      )
      return l1Match || l2Match
    })
  }

  private toggleExpand(id: number): void {
    this.expandedId = this.expandedId === id ? -1 : id
  }

  @Builder SearchBar() {
    Row() {
      SymbolGlyph($r(AppIcon.search))
        .fontSize(26)
        .margin({ left: 20, right: 8 })
      TextInput({ placeholder: '搜索科室', text: this.search })
        .fontSize(30)
        .backgroundColor(Color.Transparent)
        .layoutWeight(1).height(60)
        .placeholderColor($r('app.color.text_hint'))
        .onChange(v => this.search = v)
    }
    .width('92%').height(60)
    .backgroundColor($r('app.color.input_bg'))
    .borderRadius(999)
    .margin({ top: 16, bottom: 16, left: 16, right: 16 })
  }

  build() {
    Column() {
      this.SearchBar()

      if (this.getFilteredTree().length === 0) {
        Blank().layoutWeight(1)
        Column() {
          SymbolGlyph($r(AppIcon.emptyBox))
            .fontSize(56)
            .margin({ bottom: $r('app.float.sp_8') })
          Text('暂无匹配科室')
            .fontSize(22)
            .fontColor($r('app.color.text_hint'))
        }
        .width('100%')
        .padding({
          top: $r('app.float.sp_24'),
          bottom: $r('app.float.sp_24')
        })
        Blank().layoutWeight(1)
      } else {
        List() {
          ForEach(this.getFilteredTree(), (l1: DepartmentTreeNode) => {
            ListItem() {
              Column() {
                // 一级科室卡片（可展开）
                Column() {
                  Row() {
                    Stack() {
                      Circle().width(56).height(56).borderRadius(14).backgroundColor($r('app.color.primary_light'))
                      StethoscopeIcon({ customSize: 52, color: $r('app.color.primary') })
                    }.margin({ right: 14 })
                    Column() {
                      Text(l1.name)
                        .fontSize(23)
                        .fontWeight(700)
                        .fontColor($r('app.color.text_primary'))
                      if (l1.description) {
                        Text(l1.description)
                          .fontSize(17)
                          .fontColor($r('app.color.text_secondary'))
                          .margin({ top: 6 })
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                    SymbolGlyph($r(this.expandedId === l1.id ? AppIcon.dropDown : AppIcon.forward))
                      .fontSize(28)
                      .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
                  }
                  .width('92%')
                  .padding(18)
                  .alignSelf(ItemAlign.Center)
                }
                .width('100%')
                .backgroundColor($r('app.color.bg_card'))
                .borderRadius(16)
                .onClick(() => this.toggleExpand(l1.id))

                // 二级科室列表（展开时显示）
                if (this.expandedId === l1.id) {
                  Column() {
                    ForEach((l1.children ?? []), (l2: DepartmentTreeNode) => {
                      Column() {
                        Row() {
                          Text(l2.name)
                            .fontSize(21)
                            .fontColor($r('app.color.text_primary'))
                            .layoutWeight(1)
                          SymbolGlyph($r(AppIcon.forward))
                            .fontSize(22)
                        }
                        .width('90%')
                        .padding({ top: 16, bottom: 16, left: 16, right: 16 })
                        .margin({ top: 0, bottom: 0, left: 16, right: 16 })
                        .border({ width: { bottom: 1 }, color: { bottom: $r('app.color.bg_page') } })
                      }
                      .width('100%')
                      .onClick(() => {
                        try {
                          router.pushUrl({ url: Route.DOCTOR_LIST, params: { departmentId: l2.id } })
                        } catch (_) {}
                      })
                    }, (l2: DepartmentTreeNode) => String(l2.id))
                  }
                  .width('100%')
                  .backgroundColor($r('app.color.bg_card'))
                  .borderRadius(0)
                  .margin({ top: 8 })
                  .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
                }
              }
              .width('100%')
              .margin({ bottom: 10 })
            }
            .width('100%')
          }, (l1: DepartmentTreeNode) => String(l1.id))
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
