# 东软云医院预约挂号系统

一个面向患者的鸿蒙预约挂号应用，以及面向系统管理员的 Web 后台。

项目的开发前置分析与实施约定位于 [`docs/`](docs/)。建议在编码前由全组确认需求范围、数据规则和验收标准。

## 技术栈

- 服务端：Spring Boot 3、JDK 17、MyBatis-Plus（或 MyBatis-Flex）、MySQL 8、Redis 7.2.5、RocketMQ 5.3.0、JWT
- 管理端：Vue 3、Vite、Element Plus、Pinia、Axios
- 移动端：HarmonyOS / ArkTS / ArkUI / DevEco Studio

## 文档索引

- [01-项目立项与范围](docs/01-项目立项与范围.md)
- [02-软件需求规格说明书](docs/02-软件需求规格说明书.md)
- [03-技术方案与数据设计](docs/03-技术方案与数据设计.md)
- [04-项目计划、测试与验收](docs/04-项目计划、测试与验收.md)
- [05-数据库设计说明](docs/05-数据库设计说明.md)
- [MySQL 8 建库脚本](database/01_schema.sql)
- [演示基础数据脚本](database/02_demo_seed.sql)
