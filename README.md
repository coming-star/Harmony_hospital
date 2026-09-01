# 东软云医院预约挂号系统

## 项目简介

一个面向患者的鸿蒙预约挂号应用，以及面向系统管理员的 Web 后台。

项目的开发前置分析与实施约定位于 [`docs/`](docs/)。建议在编码前由全组确认需求范围、数据规则和验收标准。

## 技术栈

- 服务端：Spring Boot 3、JDK 17、MyBatis-Plus（或 MyBatis-Flex）、MySQL 8、Redis 7.2.5、RocketMQ 5.3.0、JWT
- 管理端：Vue 3、Vite、Element Plus、Pinia、Axios
- 移动端：HarmonyOS / ArkTS / ArkUI / DevEco Studio

## 项目结构

```
group-12-repo/
├── docs/                          # 需求、设计与流程契约文档
├── Hos_App/
│   ├── his-springboot/            # 后端：Spring Boot 3 + MyBatis-Plus
│   │   └── src/main/resources/db/ # 建库与演示数据脚本
│   ├── his-web/                   # 管理端：Vue 3 + Vite + Element Plus + Pinia
│   └── his-harmony/                # 移动端：HarmonyOS / ArkTS（待搭建）
├── gp12-项目进度计划跟踪表.xlsx
└── README.md
```

## 快速开始

### 环境要求

- JDK 17、Maven 3.9+
- MySQL 8.0+（本地默认 `root/123456`，见 `Hos_App/his-springboot/src/main/resources/application.yml`）
- Node.js 18+（管理端）

### 1. 初始化数据库

```bash
mysql -u root -p < Hos_App/his-springboot/src/main/resources/db/01_schema.sql
mysql -u root -p < Hos_App/his-springboot/src/main/resources/db/02_demo_seed.sql   # 可选，导入演示数据
```

演示数据包含管理员账号 `admin / admin123` 和患者账号（手机号 `13800000002`~`13800000005`，密码均为 `password`）。

### 2. 启动后端

```bash
cd Hos_App/his-springboot
mvn spring-boot:run
```

启动成功后访问 `http://localhost:8081/doc.html`（Knife4j 接口文档），能看到接口列表即说明后端已就绪。

### 3. 启动管理端

```bash
cd Hos_App/his-web
npm install
npm run dev
```

按终端提示打开本地地址（通常是 `http://localhost:5173`），用 `admin / admin123` 登录。

### 4. 移动端

`Hos_App/his-harmony` 尚未搭建，见项目结构说明。

## 核心功能

### 用户端 / 鸿蒙端

| 序号 | 功能模块 | 功能说明 |
|------|---------|---------|
| 1 | 注册登录 | 手机号 + 密码注册、登录，JWT 身份验证 |
| 2 | 首页 | 搜索、轮播图、预约/挂号记录等快捷入口 |
| 3 | 预约科室 | 科室关键字搜索，一级/二级科室展开 |
| 4 | 可用号源 | 未来 7 日号源，按日期、号别筛选余号 |
| 5 | 预约下单 | 选择医生、时段、就诊人，生成待支付订单 |
| 6 | 支付与订单 | 模拟支付、待支付取消、15 分钟超时自动关闭 |
| 7 | 就诊人管理 | 添加、编辑、删除就诊人信息 |
| 8 | 我的 | 头像、昵称、挂号记录、就诊人绑定、退出登录 |
| 9 | AI 管家 | 科室推荐、号源查询、生成预约草稿（需二次确认下单） |

### 系统管理员端 / 管理端

| 序号 | 功能模块 | 功能说明 |
|------|---------|---------|
| 1 | 登录与框架 | 管理员登录，左右布局后台，权限路由拦截 |
| 2 | 工作台 | 统计用户数、科室数、医生数、今日预约数 |
| 3 | 用户管理 | 患者账号分页查询、筛选、新增、编辑、停用、逻辑删除 |
| 4 | 科室管理 | 科室增删改查、树形展示、按名称/类型筛选 |
| 5 | 医生管理 | 医生档案维护、挂号级别关联、排班关联 |
| 6 | 排班管理 | 排班规则（星期、上下午、时段限额）维护与预览 |
| 7 | 挂号级别 | 号别编码、名称、费用、限额、排序维护 |
| 8 | 挂号记录 | 挂号单查询、状态筛选、查看详情、取消订单 |

## API 接口文档

（待补充）

## 团队分工

（待补充）
