# Git 协作开发规范

> 版本：v1.0（交付版） ｜ 更新日期：2026-09-05
> 远程仓库：Gitee `group-12-repo`，主分支 `master`

---

## 1. 分支策略

| 分支 | 用途 | 谁可推送 |
| --- | --- | --- |
| `master` | 主干，始终保持可编译、可演示 | 全员（合并后推送） |
| `feature/harmony-base` | 鸿蒙底座框架（主题/请求封装/路由/通用组件） | 底座负责人 |
| `feature/harmony-<名字/模块>` | 各人功能分支，如 `feature/harmony-wangyuyang` | 分支负责人 |

**规则**：

1. 后端、Web 管理端开发期按模块天然隔离，直接在 master 上小步提交；鸿蒙端四人并行，走 feature 分支。
2. 每天开工前先 `git pull`；每天至少提交 1 次，下班前把 feature 分支合并回 master。
3. 合并顺序：先把 master 合进自己的 feature 分支解决冲突 → 本地编译验证 → 再合回 master。
4. 禁止 `git push --force` 到 master；禁止在没编译验证的状态下推送。

## 2. 提交信息格式

```
<类型>(<范围>): <一句话说明>
```

| 类型 | 用途 | 示例 |
| --- | --- | --- |
| feat | 新功能 | `feat(后端+鸿蒙): 接入 DeepSeek AI 导诊` |
| fix | 修 Bug | `fix(鸿蒙): 修复雪花大ID精度丢失导致支付失败` |
| ui | 纯样式调整 | `ui(鸿蒙): 设置页字号放大、弹窗背景统一` |
| docs | 文档 | `docs: 更新接口文档` |
| merge | 分支合并 | `合并：成员C feature/harmony-wangyuyang 最新修复` |

要求：

- 一次提交只做一件事（一个接口、一个页面、一个 Bug），不要攒几天的改动一个大 commit。
- 说明写"改了什么、为什么"，不写"修改""更新"这种废话。
- 涉及共享文件（接口契约、数据库脚本、主题令牌）改动前先在群里说一声。

## 3. 标准工作流（每天）

```bash
git pull                      # 1. 先拉最新
git checkout -b feature/xxx   # 2. 鸿蒙端开功能分支（后端/Web 可省略）
# ...编码、本地编译验证...
git add <具体文件>             # 3. 只 add 本次相关文件，禁止 git add -A 闭眼提交
git commit -m "feat(范围): 说明"
git push origin feature/xxx   # 4. 推自己的分支
# 5. 合回 master：
git checkout master && git pull
git merge feature/xxx         # 解决冲突后编译验证
git push origin master
```

## 4. 冲突处理与排查方法

1. 冲突文件逐个看 `<<<<<<<` / `=======` / `>>>>>>>` 三段，**理解两边各自改了什么**再选，不要无脑选某一边。
2. 怀疑合并丢代码时，用命令对比"合并结果"和"对方分支原版"：
   ```bash
   git diff <合并提交> <对方分支> -- <文件路径>
   git log --oneline --graph --all   # 看分支合并图
   ```
3. **真实案例**：本项目曾出现"成员分支已实现的功能在 master 上丢失"，排查方法就是 `git diff` 逐文件对比合并结果与源分支，定位到冲突解决时误选了旧代码。
4. 解决冲突后必须完整编译一次再提交。

## 5. 提交黑名单（.gitignore）

以下内容**不得提交**，已在 `.gitignore` 配置：

- IDE 配置：`.idea/`、`*.iml`
- 构建缓存与产物：`.hvigor/`、`.hvigor-home/`、`target/`、`node_modules/`、`build/`、`dist/`
- JVM 崩溃日志：`hs_err_pid*.log`
- 系统垃圾：`.DS_Store`、`Thumbs.db`
- **密钥**：`DEEPSEEK_API_KEY` 等只走环境变量，禁止写进代码或文档

## 6. 账号与安全

- Gitee 账号开启凭据管理，不要把账号密码硬编码进远程地址截图外发。
- 数据库密码、API Key 等出现在 `application.yml` 的仅为本地演示配置，正式环境一律走环境变量。
