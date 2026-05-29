# instructions.md — Agent 着陆页

> DeepSeek TUI 会在每个会话开始时自动注入此文件。
> 本文件是"目录页"，详细内容指向 `harness/` 和 `docs/`。

---

## 项目身份

<!-- 一句话说清楚这是什么项目，给 agent 建立全局认知。来源：L02 "给地图不给说明书" -->

**项目名称**：居净清单 (JuJingList) — 家庭事务提醒应用
**一句话描述**：基于 Flutter 的纯本地离线家庭清洁事务管理工具，支持语音录入、智能语义解析、分组管理和定时提醒调度。全程无云端上传，保障用户隐私。

---

## 技术栈

<!-- agent 需要知道用什么语言、什么框架、什么版本。来源：L02 指令子系统 -->

- **语言**：Dart 3.x
- **框架**：Flutter 3.22+
- **构建工具**：flutter build
- **包管理**：flutter pub
- **运行时**：Android 10+, iOS 15+
- **状态管理**：Riverpod
- **数据库**：Drift (SQLite)
- **测试框架**：flutter_test

---

## 首次运行

<!-- agent 拿到一个新环境，需要知道怎么启动项目。来源：L06 启动就绪清单 -->

```bash
# 安装依赖
flutter pub get

# 代码生成 (Drift 数据库)
dart run build_runner build

# 启动开发环境
flutter run

# 运行全部验证
flutter analyze && flutter test
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
flutter analyze

# L2 运行时验证（单元测试）
flutter test test/unit/

# L2 运行时验证（集成测试）
flutter test test/integration/

# L3 端到端验证
flutter test test/e2e/

# 一键全量验证
flutter analyze && flutter test
```

---

## 全局硬约束（摘要）

<!-- 来源：L02 "约束而非微操" -->

> 以下为最关键的约束摘要，**全量约束请见 `harness/CONSTRAINTS.md`**。

1. **纯本地离线**：禁止任何形式的网络请求、数据上传、日志上报。所有数据全程本地处理。
2. **权限最小化**：仅申请麦克风、通知、存储权限，按需申请，禁止多余权限。
3. **系统闹钟强制**：定时提醒必须基于系统闹钟/日历实现，禁止纯应用层定时器。
4. **模型不入包**：ASR/LLM 模型文件不打包进安装包，首次启动后断点续传下载。
5. **最低适配**：Android 10+、iOS 15+，平台 API 调用须做版本兼容检查。

---

## 会话流程

<!-- 来源：L06 初始化阶段、L12 清洁状态 -->

### 每次会话开始

1. 读 `harness/CONSTRAINTS.md`
2. 读 `harness/ARCHITECTURE.md`
3. 读 `harness/PROGRESS.md`
4. 读 `harness/feature_list.json`
5. 读 `harness/SESSION-HANDOFF.md`（如有未完成工作）
6. 运行 `flutter analyze` 确认仓库处于一致状态

### 每次会话结束

1. 更新 `harness/PROGRESS.md`
2. 更新 `harness/feature_list.json`（如状态有变化）
3. 写 `harness/SESSION-HANDOFF.md`
4. 运行 `flutter analyze && flutter test` 确认一致状态
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

---

## 模块地图

<!-- 项目 src/ 模块分布，agent 快速了解代码组织 -->

```
src/
├── core/
│   ├── common/         # 通用模块：常量、数据模型、工具类、权限管理
│   ├── database/       # 数据库模块：Drift(SQLite) 分组+提醒 CRUD
│   ├── voice/          # 语音模块：录音、离线ASR、语义解析
│   ├── reminder/       # 提醒模块：时间解析、定时调度、推迟重试
│   └── notification/   # 通知模块：系统原生通知推送
└── feature/
    ├── home/           # 首页模块：分组概览、今日待办
    ├── voice_input/    # 语音录入页：录音→识别→确认创建
    ├── group_manage/   # 分组管理页：预设+自定义分组 CRUD
    └── cleanup/        # 批量清理页：标记完成、补货提醒
```
