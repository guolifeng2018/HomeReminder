# 会话交接

---

## 下一个 Agent

- **角色**：implementer
- **任务摘要**：按方案实现 F-07（feature/home 首页）— 10 个工作单元，从 HOME-01 Provider 层到 HOME-10 barrel + 路由注册。详细拆分见 `work/planner/BREAKDOWN.md`，实现方案见 `work/planner/PLAN.md`
- **技能文件**：agents/implementer/SKILL.md

---

## 仓库状态

- **最后 commit**：F-07 planner 完成 BREAKDOWN + PLAN
- **构建状态**：`flutter analyze` 全量 1 info（F-05 范围），零 error/warning
- **测试状态**：全量 327 tests PASS

---

## F-07 方案摘要

### 工作单元（10 个）

| # | 单元 | 依赖 |
|---|------|------|
| HOME-01 | 首页 Riverpod Provider | F-02, F-03 |
| HOME-02 | 页面头部组件 | 无 |
| HOME-03 | 分组概览卡片 | 无 |
| HOME-04 | 分组卡片横向列表 | HOME-01, HOME-03 |
| HOME-05 | 今日待办时间线列表 | HOME-01 |
| HOME-06 | 状态筛选 TabBar | 无 |
| HOME-07 | 空状态组件 | 无 |
| HOME-08 | FAB 展开菜单 | 无 |
| HOME-09 | 首页组装 + 响应式布局 | HOME-02~08 |
| HOME-10 | barrel file + 路由注册 | HOME-09 |

### 并行开发建议

HOME-02/03/06/07/08 可并行（无相互依赖），HOME-01 为数据源优先开发。

### 关键文件路径

- `lib/src/feature/home/code/` — 所有源代码
- `test/unit/home/` — 所有单元测试
- `lib/src/router/app_router.dart` — 路由注册（修改）

## 已完成功能

| 功能 ID | 名称 | 状态 |
|---------|------|------|
| INIT | 环境探测 | completed |
| F-00 | Flutter 工程脚手架 | completed |
| F-01 | core/common | completed |
| F-02 | core/database | completed |
| F-03 | Riverpod 状态管理 | completed |
| F-04 | 路由系统 | completed |
| F-05 | core/reminder | completed |
| F-06 | core/notification | completed |
