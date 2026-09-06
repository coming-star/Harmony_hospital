# 鸿蒙端开发快速上手（给成员 B / C / D）

> **定位**：分工文档（`9.03日鸿蒙端分工.md`）已经写清楚了"你做哪几个页面、哪天交"；本指南写清楚"拿到现有框架后，怎么写一个页面"——常见 7 个问题一次说明白。请所有开发同学**在写第一行代码前**先通读一遍。

**本工程状态（成员 A 已搭好的底座）**：
- 目录 & 页面占位壳：**14 个页面全部注册到 `main_pages.json` 并创建了 `.ets` 骨架**，你只要在对应文件里写 UI/逻辑，**不用自己新建文件或自己注册路由**
- 工具层：`utils/theme.ets / format.ets / request.ets`
- 接口层：`api/auth.ets / department.ets / doctor.ets / slot.ets / contact.ets / order.ets / ai.ets`（7 个分模块）
- 类型层：`types/index.ets`（全部 DTO + 枚举常量）
- 状态层：`store/UserStore.ets`（登录态 + Preferences 持久化，单例 `userStore` 默认导出）
- 通用组件：`components/AppBar.ets / SectionTitle.ets / EmptyState.ets / AvatarIcon.ets / FeeTag.ets / StatusTag.ets / ConfirmDialog.ets`
- 设计令牌：颜色 / 字号 / 间距 / 圆角 全部集中在 `resources/base/element/color.json` + `float.json` + `utils/theme.ets`，**页面中禁止写硬编码颜色或硬编码字体大小**

---

## 1. 我写的页面放哪里？命名规范？

### 页面目录约定（**全部已建好占位壳**，不要自己改路径）

```
entry/src/main/ets/pages/
├─ Index.ets            ← 4 Tabs 根容器（成员 A 维护，一般不修改）
├─ HomeTab.ets          ← 首页 Tab 内容（成员 B）
├─ AppointmentTab.ets   ← 预约 Tab 入口（成员 C）
├─ AITab.ets            ← AI Tab 内容（成员 D，Tabs 页用这个）
├─ MineTab.ets          ← 我的 Tab 内容（成员 D，Tabs 页用这个）
├─ auth/Login.ets       ← 登录（成员 B）
├─ auth/Register.ets    ← 注册（成员 B）
├─ appointment/AppointmentIndex.ets  ← 预约占位跳转（成员 C）
├─ appointment/DepartmentSelect.ets  ← 科室选择（成员 C）
├─ appointment/DoctorList.ets        ← 医生+时段列表（成员 C）
├─ appointment/ContactSelect.ets     ← 就诊人选择（成员 C）
├─ appointment/OrderConfirm.ets      ← 订单确认（成员 C）
├─ appointment/BookingSuccess.ets    ← 预约成功（成员 C）
├─ ai/AIChat.ets          ← AI 聊天子页（成员 D）
└─ mine/
   ├─ MineIndex.ets      ← 我的子路由壳（如果 Tabs 里直接用 MineTab 就不启用它）
   ├─ OrderRecord.ets    ← 挂号记录（成员 D）
   ├─ ContactManage.ets  ← 就诊人管理（成员 D）
   └─ Settings.ets       ← 设置（成员 D）
```

### 命名规范
- 组件类：**PascalCase**（`HomeTab`、`AppBar`、`DoctorList`）
- 文件名：**同组件类名** + `.ets`（`AppBar.ets` 里 `export struct AppBar`）
- 变量 / 方法：**camelCase**（`listContacts`、`doctorList`）
- 常量 / 枚举：**UPPER_SNAKE**（`DEFAULT_PAGE_SIZE`、`Relation.SELF`）

---

## 2. 怎么路由跳转？怎么传参数？

### 统一用 `router`，并从 `utils/theme.ets` 的 **`Route` 常量**取页面路径

```typescript
import router from '@ohos.router'
import { Route } from '../../utils/theme.ets'

// 无参数
router.pushUrl({ url: Route.DEPT_SELECT })

// 带参数（Object，类型都是 Object 因为 router API 的 params 是 Record<string, Object>；页面里自己 Number(...) 转）
router.pushUrl({ url: Route.DOCTOR_LIST, params: { departmentId: 2101, visitDate: '2026-09-04' } })

// 替换当前栈顶（如：预约成功页 → 跳挂号记录，不允许返回确认页）
router.replaceUrl({ url: Route.ORDER_RECORD, params: { tab: 'PAID' } })

// 返回上一页
router.back()
```

### 子页面 `aboutToAppear` 里取参数

```typescript
import router from '@ohos.router'

@Entry
@Component
struct DoctorList {
  @State departmentId: number = 0
  @State visitDate: string = ''

  aboutToAppear() {
    const p = router.getParams() as Record<string, Object> | undefined
    if (p) {
      if (p['departmentId']) this.departmentId = Number(p['departmentId'])
      if (p['visitDate'])    this.visitDate    = String(p['visitDate'])
    }
    this.loadSlots()
  }

  // ...
}
```

> 所有路由路径名已经在 `Route` 类里集中定义好了，**不要自己写字符串路径**，避免拼写错误找不到页面。

---

## 3. 怎么调接口？异常怎么办？401 会发生什么？

### 3.1 API 调用只从 `api/*.ets` 模块导入方法，禁止页面直接用 http.request

```typescript
// ✅ 正确写法
import * as orderApi from '../../api/order.ets'
import { Format } from '../../utils/format.ets'
import type { CreateOrderRequest, OrderDetail } from '../../types'

async function submit(): Promise<void> {
  const req: CreateOrderRequest = {
    slotId: this.slotId,
    contactId: this.contactId,
    idempotencyKey: Format.uuid()   // 幂等键 UUID 用这个工具方法
  }
  try {
    const order: OrderDetail = await orderApi.createOrder(req)
    // ... 接口成功，做下一步跳转
  } catch (e) {
    // ❗ 不用自己弹 toast！request.ets 里已经统一弹过了（如"该时段已约满"）
    // 这里只要处理 UI 还原，例如：this.submitting = false
  }
}
```

### 3.2 401、403、429、500 等错误的统一处理

在 `utils/request.ets` 里已经全部处理好了：
- **401**：自动清 UserStore、弹 toast「登录已失效，请重新登录」、`router.replaceUrl(Login)`
- **403**：弹 toast「您没有权限进行此操作」
- **429**：弹 toast「请求过于频繁，请稍后再试」
- **5xx**：弹 toast「服务器繁忙，请稍后重试」
- **网络错误（超时 / 不可达）**：弹 toast「网络异常，请检查网络后重试」
- **409001 ~ 409006**：按后端错误码映射成对应中文 toast（见分工文档 §错误码目录）

> 页面代码里只要处理"成功路径"和**业务层面的异常 UI 还原**（如按钮恢复可点、loading 态关闭），不要重复写 toast。

### 3.3 需要显示 loading 怎么办？

`request.ets` 每个方法（`get/post/put/del`）都支持第三个参数 `opts?: RequestOptions`，传 `{ loading: true }` 即可：

```typescript
// 会在期间弹系统级 loading
await orderApi.createOrder(req)  // 内部已经传了 { loading:true }（见 order.ets 定义）
```

`orderApi.createOrder / payOrder / cancelOrder` 这些用户感知强的接口，封装层已经默认开了 `loading:true`，你不用额外传。

---

## 4. 颜色 / 字号 / 间距去哪里拿？怎么保证和参考图风格一致？

### 4.1 颜色：用 `$r('app.color.xxx')`，所有色名在 `color.json` 里集中

```
主色（品牌蓝，所有按钮/Tabs选中/AppBar）：$r('app.color.primary')  ← #0A66C2
主色浅底（输入框/卡片高亮区）：$r('app.color.primary_light')       ← #E8F1FC
输入框浅灰背景（参考图登录页输入框）：$r('app.color.input_bg')     ← #F5F7FA
页面背景（最外层）：$r('app.color.bg_page')                       ← #FAFBFC
卡片白底：$r('app.color.bg_card')                                ← #FFFFFF
主文字：$r('app.color.text_primary')（#1A1A1A，标题/正文）
副标题：$r('app.color.text_secondary')（#5B6370，辅助灰文字）
辅助文字：$r('app.color.text_hint')（#9CA3AF，placeholder/小字）
白色文字/图标：$r('app.color.text_white')（#FFFFFF）
危险红（退出登录/取消订单）：$r('app.color.danger')（#DB3A2F）+ danger_light
成功绿（预约成功页）：$r('app.color.success') + success_light
警告橙（待支付Tag）：$r('app.color.warning') + warning_light
分割线：$r('app.color.divider')（#EAECF0）
```

**禁止在页面里写 `#0A66C2` 或 `Color.Blue` 这种硬编码**，否则团队改风格时要到处搜。

### 4.2 字号：`$r('app.float.fs_XX')`（10/12/14/16/18/20/24/28/32 共 9 级）

参考图匹配对照：
```
页面主标题（登录页"欢迎回来" / 首页"东软云医院"）：fs_28 / fs_32 + Bold
卡片大标题（部门名 / 医生姓名）：fs_18 / fs_20 + 600
正文 / 输入框文字：fs_14 / fs_15
辅助说明（科室简介/Tab标签）：fs_12 / fs_13
超大数字（金额）：fs_20 / fs_24 + Bold
```

### 4.3 间距（margin/padding）：`$r('app.float.sp_XX')`（4/8/12/16/20/24/32）

参考图是"呼吸感很强"的设计，**不要省空间挤在一起**，卡片四周一般 `sp_16` 或 `sp_24`。

### 4.4 圆角：`radius_sm 8vp / radius_md 16vp / radius_lg 24vp / radius_pill 9999vp（胶囊按钮）`
- 按钮：`radius_lg`（大圆角，24vp）
- 输入框 & 卡片：`radius_md`（16vp）
- 小标签（状态Tag、芯片）：`radius_pill`

---

## 5. 通用组件怎么 import & 怎么用？

| 组件 | 文件名 | 适用场景 |
|---|---|---|
| `AppBar` | `components/AppBar.ets` | **所有非 Tabs 子页面必加顶部蓝色 AppBar**（登录/注册/科室选择/医生列表/就诊人选择/订单确认/成功/AI聊天/挂号记录/就诊人管理/设置）|
| `SectionTitle` | `components/SectionTitle.ets` | "推荐科室"、"推荐医生"等分组标题 |
| `EmptyState` | `components/EmptyState.ets` | 空数据、无搜索结果等空态页 |
| `AvatarIcon` | `components/AvatarIcon.ets` | 医生头像 / 用户头像（没有资源图片时自动用首字母圆形）|
| `FeeTag` | `components/FeeTag.ets` | 金额展示（后端分→自动转元）|
| `StatusTag` | `components/StatusTag.ets` | 订单 4 状态胶囊标签（自动配色）|
| `ConfirmDialog` | `components/ConfirmDialog.ets` | 退出登录/取消订单/删除就诊人等危险二次确认 |

### 示例 1：AppBar（每个子页面顶部第一行写它）
```ts
import { AppBar } from '../../components/AppBar.ets'
@Entry
@Component
struct OrderRecord {
  build() {
    Column() {
      AppBar({ title: '挂号记录' })  // 自带返回箭头，点了自动 router.back()
      // 下面是页面主体 ...
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
```

### 示例 2：StatusTag + FeeTag（订单卡片常见组合）
```ts
import { StatusTag } from '../../components/StatusTag.ets'
import { FeeTag } from '../../components/FeeTag.ets'
import type { OrderDetail, OrderStatus } from '../../types'

// 每个订单卡片里：
Row() {
  Column().layoutWeight(1) {
    Text(o.departmentName).fontSize(16).fontWeight(600)
    Text(`${o.doctorName} · ${o.levelName}`).fontSize(12).fontColor($r('app.color.text_secondary'))
  }
  StatusTag({ status: o.status })   // 右上角胶囊状态
}
Row() {
  Text(`${visitDate}  ${startTime}-${endTime}`)
  Blank()
  FeeTag({ fen: o.amountFen })      // 自动分转元
}.margin({ top: 8 })
```

### 示例 3：ConfirmDialog（危险动作）
```ts
@State logoutShow = false
Button('退出登录').onClick(() => { this.logoutShow = true })

// 推荐用 bindSheet（Center Sheet）：
.bindSheet($$$this.logoutShow,
  ConfirmDialog({
    show: $$$this.logoutShow,
    message: '确定要退出登录吗？',
    danger: true,
    onConfirm: () => { userStore.logout() }
  }),
  { height: 280, preferType: SheetType.CENTER, showClose: false, dragBar: true }
)
```

---

## 6. 每天 Git 流程？分支怎么建？

### 分支策略

| 分支 | 谁用 | 说明 |
|---|---|---|
| `master` | 所有人 | 最新合入，每天早上 `rebase` 一次到最新 |
| `feature/harmony-base` | 成员 A 已合入，已删或冻结 | 块 A 主开发分支；B/C/D 都**从它之后的 master checkout 出来** |
| `feature/harmony-b-entrance` | 成员 B | 入口三件套（登录/注册/首页）|
| `feature/harmony-c-appointment` | 成员 C | 预约全流程（科室→成功页）|
| `feature/harmony-d-mine` | 成员 D | 我的页+子页+AI |

### 一个标准的「一天循环」
```bash
# 1. 早上先同步 master（非常重要，避免晚上合并时冲突爆炸）
git checkout master
git pull origin master
git checkout feature/harmony-b-entrance
git rebase master

# 2. 白天写代码
# 3. 下午 5:30 之前整理提交（不要堆到晚上一大堆代码一次 push）
git add .
git commit -m "feat(鸿蒙-入口):完成登录页表单校验+联调登录接口
- 主色蓝AppBar+听诊器图标+灰底输入框
- 校验手机正则/密码长度+错误toast
- 登录成功写UserStore+跳首页"

# 4. 推远端 + 提 Pull/Gitee Merge Request
git push origin feature/harmony-b-entrance
# 然后在 Gitee 网页提一个 MR 到 master，@组长 review
```

### 提交信息格式（中文）
**前缀+范围+标题，空一行+要点列表**（跟你项目后端同学用的那种格式一样）：
```
feat(鸿蒙-我的):完成挂号记录4Tab+立即支付+取消预约
- Tab切换自动刷新list
- 立即支付调 order.pay(id)，确认后弹"支付成功"
- 取消预约走ConfirmDialog+order.cancel(id)

fix(鸿蒙-框架):修复 UserStore 401 后 token 不同步的问题

refactor(鸿蒙-预约):抽公共 DoctorSlotCard 组件减少重复代码

docs(鸿蒙):补充开发指南的跳转参数说明
```

---

## 7. 联调后端接口：BASE_URL 改哪？

> 不同模拟器/真机环境 IP 不一样：

| 环境 | `BASE_URL` 值 |
|---|---|
| Android 模拟器（默认）| **`http://10.0.2.2:8080`**（已在 request.ets 默认写好）|
| iOS 模拟器 | `http://127.0.0.1:8080` |
| 真机（手机 WiFi 与电脑同一局域网）| `http://<电脑局域网 IP>:8080`（Win 上 `ipconfig` 查 IPv4，如 192.168.1.100）|
| 已部署服务器 | `https://你的域名` |

### 集中修改位置
**只改一个文件**：`entry/src/main/ets/utils/request.ets` 顶部的：
```ts
export const BASE_URL = 'http://10.0.2.2:8080'
```
⚠️ **不要在 `api/*.ets` 或页面里自己写 `http://192.168.1.100:8080` 硬编码**，否则合并时会互相覆盖。提交前务必把 BASE_URL 还原回默认 `10.0.2.2`（或者留一份注释说明本地测试 IP，默认不改）。

---

## 8. 一段"能跑的最小完整例子"——写一个挂号记录页面（成员 D 真实工作）

```typescript
// 1. 顶部引入：AppBar / 路由 / API / 类型 / 组件
import router from '@ohos.router'
import { AppBar } from '../../components/AppBar.ets'
import { StatusTag } from '../../components/StatusTag.ets'
import { FeeTag } from '../../components/FeeTag.ets'
import { EmptyState } from '../../components/EmptyState.ets'
import * as orderApi from '../../api/order.ets'
import { Format } from '../../utils/format.ets'
import { Route } from '../../utils/theme.ets'
import type { OrderDetail, PageResult } from '../../types'
import { promptAction } from '@kit.ArkUI'

@Entry
@Component
struct ExamplePage {
  @State list: OrderDetail[] = []
  @State page: number = 1
  @State size: number = 20

  async aboutToAppear() {
    try {
      const r: PageResult<OrderDetail> = await orderApi.listMyOrders({ page: this.page, size: this.size })
      this.list = [...r.records]   // 不可变更新
    } catch (_) { /* request 已 toast */ }
  }

  async cancel(o: OrderDetail) {
    try {
      await orderApi.cancelOrder(o.id)
      promptAction.showToast({ message: '已取消' })
      this.aboutToAppear()
    } catch (_) {}
  }

  @Builder Card(o: OrderDetail) {
    Column() {
      Row() {
        Column().layoutWeight(1) {
          Text(o.departmentName).fontSize(16).fontWeight(600)
            .fontColor($r('app.color.text_primary'))
          Text(`${o.doctorName} · ${o.levelName}`).fontSize(12)
            .fontColor($r('app.color.text_secondary')).margin({top:4})
        }
        StatusTag({ status: o.status })
      }.width('100%')
      Row() {
        Text(`${Format.date(o.visitDate)}  ${Format.time(o.startTime)}-${Format.time(o.endTime)}`)
          .fontSize(13).fontColor($r('app.color.text_secondary'))
        Blank()
        FeeTag({ fen: o.amountFen })
      }.margin({top:8})
    }
    .width('92%').padding(16)
    .margin({top:12}).alignSelf(ItemAlign.Center)
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius($r('app.float.radius_md'))
  }

  build() {
    Column() {
      AppBar({ title: '我的挂号' })
      if (this.list.length === 0) {
        EmptyState({
          hint: '还没有挂号记录', emoji:'📋',
          actionText: '去预约', routeTo: Route.APPOINTMENT
        })
      } else {
        List() {
          ForEach(this.list, (o: OrderDetail) => {
            ListItem() { this.Card(o) }.width('100%')
          }, (o: OrderDetail) => String(o.id))
        }.layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor($r('app.color.bg_page'))
  }
}
```

**可以直接复制这个结构到你的页面骨架里，改一下数据字段就是一张可用的列表页。**

---

## 9. 成员 A（组长）的联系方式 & 问题升级顺序

1. **遇到 "接口字段不知道传什么 / 返回什么"** → 直接查 `types/index.ets` 对应 interface，找不到查后端 Java DTO，再找不到群里 @成员 A 并附截图
2. **遇到 "报错 ArkTS 语法不会写"** → 先查 Harmony 官方文档或群里问一句（最好附最小代码）
3. **遇到 "BASE_URL 怎么也连不上后端"** → ①先确定手机和电脑同 WiFi 或模拟器类型 ②Win 临时关防火墙（或开 8080 入站规则）③@成员 A，一起远程看
4. **提交 / 合并冲突不会处理** → 不要硬 push -f！先 @成员 A 一起看

---

**完。祝顺利！** 🚀
