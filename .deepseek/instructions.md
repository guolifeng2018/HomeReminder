# instructions.md — Agent 着陆页

> DeepSeek TUI 会在每个会话开始时自动注入此文件。
> 本文件是"目录页"，详细内容指向 `harness/` 和 `docs/`。

---

## 项目身份

<!-- 一句话说清楚这是什么项目，给 agent 建立全局认知。来源：L02 "给地图不给说明书" -->

**项目名称**：<!-- 如 HomeReminder — 家庭事务提醒应用 -->
**一句话描述**：<!-- 如 基于 Flutter 的跨平台提醒工具，支持语音录入和智能调度 -->

---

## 技术栈

<!-- agent 需要知道用什么语言、什么框架、什么版本。来源：L02 指令子系统 -->

- **语言**：<!-- 如 Dart 3.x -->
- **框架**：<!-- 如 Flutter 3.x -->
- **构建工具**：<!-- 如 flutter build -->
- **包管理**：<!-- 如 flutter pub -->
- **运行时**：<!-- 如 iOS 15+, Android 12+ -->

---

## 首次运行

<!-- agent 拿到一个新环境，需要知道怎么启动项目。来源：L06 启动就绪清单 -->

```bash
# 安装依赖
<!-- 如 flutter pub get -->

# 启动开发环境
<!-- 如 flutter run -->

# 运行全部验证
<!-- 如 make check -->
```

---

## 仓库地图

<!-- 告诉 agent 去哪里找什么，不要重复内容，只指路。来源：L03 就近放置、L04 拆分指令 -->

| 想知道什么 | 去哪里看 |
|-----------|---------|
| 项目架构、模块划分 | `harness/ARCHITECTURE.md` |
| 全局硬约束（完整清单） | `harness/CONSTRAINTS.md` |
| 当前进度、下一步做什么 | `harness/PROGRESS.md` |
| 功能列表和验收标准 | `harness/feature_list.json` |
| 上次会话做到哪了 | `harness/SESSION-HANDOFF.md` |
| 评审标准 | `harness/EVALUATOR-RUBRIC.md` |
| 架构决策历史 | `harness/decisions/` |
| 编码规范 | `docs/conventions.md` |
| 系统设计文档 | `docs/architecture.md` |
| 任务拆分全貌 | `docs/task-breakdown/overview.md` |

---

## 验证命令

<!-- agent 需要知道怎么检查自己做对了没有。来源：L02 反馈子系统、L09 三层终止校验 -->

```bash
# L1 静态分析
<!-- 如 dart analyze -->

# L2 运行时验证（单元 + 集成）
<!-- 如 flutter test test/unit/ test/integration/ -->

# L3 端到端验证
<!-- 如 flutter test test/e2e/ -->

# 一键全量验证
<!-- 如 make check -->
```

---

## 全局硬约束（摘要）

<!-- 来源：L02 "约束而非微操" -->

> 以下为最关键的约束摘要，**全量约束请见 `harness/CONSTRAINTS.md`**。

1. <!-- 如 必须使用 Provider 做状态管理，禁止引入其他状态管理库 -->
2. <!-- 如 禁止在 Widget 中直接访问数据库，必须通过 Repository 层 -->
3. <!-- 如 所有公开 API 必须有文档注释 -->

---

## 会话流程

<!-- 来源：L06 初始化阶段、L12 清洁状态 -->

### 每次会话开始

1. 读 `harness/CONSTRAINTS.md`
2. 读 `harness/ARCHITECTURE.md`
3. 读 `harness/PROGRESS.md`
4. 读 `harness/feature_list.json`
5. 读 `harness/SESSION-HANDOFF.md`（如有未完成工作）
6. 运行验证命令确认仓库处于一致状态

### 每次会话结束

1. 更新 `harness/PROGRESS.md`
2. 更新 `harness/feature_list.json`（如状态有变化）
3. 写 `harness/SESSION-HANDOFF.md`
4. 运行全量验证确认一致状态
5. 清理临时文件、调试代码
6. 提交所有已完成的工作

---

## 角色

<!-- 来源：L09 "干活和检查分开"、L11 三角色架构 -->

本项目使用三 agent 角色协作，你应只扮演被分配的角色：

- **planner**：选功能、标进度、出方案（`agents/planner/SKILL.md`）
- **implementer**：建模块、写代码、写测试、记决策（`agents/implementer/SKILL.md`）
- **reviewer**：三层验证、写修复单、归档（`agents/reviewer/SKILL.md`）

干活和检查必须是不同 agent，不允许自己评估自己的工作。

**每次执行角色任务时，必须新建一个独立对话。** 不要在同一个对话中切换角色，避免上下文污染和角色越界。

---

## 工作目录

<!-- 告诉 agent 产出放在哪里 -->

- `work/` — 当前功能的全部 agent 产出，每次新功能开始时从 `templates/work/` 复制
- `templates/` — 不参与归档的模板文件
  - `templates/work/` — work 目录模板（planner/implementer/reviewer 的空白产出文件）
  - `templates/src/` — src 模块模板（implementer 新建模块时的脚手架）
- `history/` — 已完成功能归档
