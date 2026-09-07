# 东软云医院预约挂号系统

一个面向患者的**鸿蒙预约挂号 App**，以及面向医院管理员的 **Web 管理后台**，后端为 Spring Boot 3 REST 服务，并接入 DeepSeek 大模型提供 AI 导诊。

## 技术栈

- **服务端**：Spring Boot 3、JDK 17、MyBatis-Plus、MySQL 8、Redis 7、RocketMQ 5.3.0、Spring Security + JWT、Knife4j(OpenAPI 3)
- **AI**：DeepSeek（deepseek-chat，OpenAI 兼容协议，JDK HttpClient 直连）
- **管理端**：Vue 3、Vite、Element Plus、Pinia、Axios
- **移动端**：HarmonyOS / ArkTS / ArkUI / DevEco Studio

## 项目结构

```
group-12-repo/
├── docs/                          # 项目交付文档（需求/数据/接口/架构/计划/UI/Git规范）
├── Hos_App/
│   ├── his-springboot/            # 后端：Spring Boot 3 + MyBatis-Plus
│   │   └── src/main/resources/db/ # 建库脚本 01_schema.sql + 演示数据 02_demo_seed.sql
│   ├── his-web/                   # 管理端：Vue 3 + Element Plus
│   └── his-harmony/               # 移动端：HarmonyOS ArkTS（15 个页面）
├── gp12-项目进度计划跟踪表.xlsx
└── README.md
```

## 环境要求

- JDK 17、Maven 3.9+
- MySQL 8.0+（本地默认 `root/123456`）
- Redis 7+（本地默认 `localhost:6379`，密码 `123456`）
- Node.js 18+（管理端）
- DevEco Studio（移动端）

## 快速开始

### 1. 初始化数据库

```bash
mysql -u root -p < Hos_App/his-springboot/src/main/resources/db/01_schema.sql
mysql -u root -p < Hos_App/his-springboot/src/main/resources/db/02_demo_seed.sql   # 演示数据
```

演示账号：管理员 `admin / admin123`；患者手机号 `13800000002`~`13800000007`，密码均为 `password`。

### 2. 启动 Redis

本地 Redis 需设置密码 `123456`（与 `application.yml` 一致），或修改配置文件中的 `spring.data.redis.password`。

### 3. 配置 AI 导诊（可选）

AI 管家需要 DeepSeek API Key，通过环境变量配置（不配置时 AI 接口提示未配置，其他功能不受影响）：

```bash
# Windows PowerShell
$env:DEEPSEEK_API_KEY="你的key"
# 或在 IDEA 运行配置的环境变量中添加 DEEPSEEK_API_KEY
```

### 4. 启动后端（端口 8081）

```bash
cd Hos_App/his-springboot
mvn spring-boot:run
```

- 接口文档（Knife4j）：http://localhost:8081/doc.html
- 首次启动会自动把排班规则展开为未来 14 天号源。

### 5. 启动管理端

```bash
cd Hos_App/his-web
npm install
npm run dev
```

按终端提示打开地址（通常 http://localhost:5173 ），用 `admin / admin123` 登录。

### 6. 运行鸿蒙 App

用 DevEco Studio 打开 `Hos_App/his-harmony`，等待依赖同步后启动模拟器/真机运行；
后端地址在 `entry/src/main/ets/utils/request.ets` 中配置（默认指向本机 8081，模拟器访问宿主机用 `http://10.0.2.2:8081` 或局域网 IP）。

## 核心功能

**患者端（鸿蒙 App）**：注册登录（JWT）、首页（Banner/快捷入口/热门科室）、科室树搜索、未来 7 天号源与号别筛选、就诊人管理（一人绑定多人）、下单→收银台模拟支付→支付成功、挂号记录（待支付/已支付/已取消、取消退号）、AI 导诊对话、设置。

**管理端（Web）**：工作台统计（今日预约/7 日趋势/科室排行）、用户管理、科室管理、医生管理、挂号级别、排班规则（保存后自动重新生成号源）、挂号记录与取消。

**系统级保障**：Redis 分布式锁 + 号源乐观锁 + 幂等键三重防超卖；挂号接口每分钟 5 次限流；待支付订单 15 分钟超时自动取消；热点数据 Cache-Aside 缓存；雪花大 ID 全链路字符串传输防前端精度丢失。

## 文档

| 文档 | 链接 |
| --- | --- |
| 需求分析 | [docs/01-需求分析文档.md](docs/01-需求分析文档.md) |
| 数据设计 | [docs/02-数据设计文档.md](docs/02-数据设计文档.md) |
| 接口文档 | [docs/03-接口文档.md](docs/03-接口文档.md) |
| Git 协作规范 | [docs/04-Git协作开发规范.md](docs/04-Git协作开发规范.md) |
| 开发计划（甘特图） | [docs/05-项目开发计划.md](docs/05-项目开发计划.md) |
| 系统架构设计 | [docs/06-系统架构设计.md](docs/06-系统架构设计.md) |
| 项目页面效果 | [docs/07-项目页面效果.md](docs/07-项目页面效果.md) |
| 项目总结（成果 / 踩坑 / 暂未实现功能） | [docs/08-项目总结.md](docs/08-项目总结.md) |
| 核心实现说明（Redis / 状态机 / 号源生成 / 并发防超卖 / AI 导诊） | [docs/说明文档/](docs/说明文档/) |
