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

（待补充）

## API 接口文档

（待补充）

## 团队分工

（待补充）
