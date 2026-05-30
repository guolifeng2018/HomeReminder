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

### 角色判定

按「自动角色识别」规则确定当前角色：

- **具体角色**（planner / implementer / reviewer / initer）→ 读取对应 `agents/<role>/SKILL.md`，按 SKILL 定义的工作流程执行该角色的全部任务
- **无法确定** → 进入**编排者模式**，启动 Agent 循环（详见下方「Agent 循环编排」），自动推进功能开发

### Agent 循环编排（编排者模式）

编排者不直接执行编码或评审，而是通过 `agent_open` / `agent_eval` / `agent_close` 串行调度各角色子 agent，完整执行功能开发循环。

**核心原则**：每次只有一个子 agent 运行。必须等待当前 agent 完成并关闭后，才能启动下一个。

**循环步骤**：

**步骤 1 — 判定起点**

读取 `harness/SESSION-HANDOFF.md` 中的「## 下一个 Agent」节，确定当前应启动哪个角色：

- 若 SESSION-HANDOFF 明确指定角色 → 使用该角色
- 若 SESSION-HANDOFF 不存在或指向已完成的循环 → 从 `planner` 开始新功能（扫描 `feature_list.json` 中第一个 `pending` 功能）
- 若 reviewer 刚完成归档 → SESSION-HANDOFF 已指向 planner → 开始下一功能循环

**步骤 2 — 更新交接文件**

在启动子 agent 前，确保 `harness/SESSION-HANDOFF.md` 中的「下一个 Agent」节正确指向即将启动的角色。子 agent 启动后会读取该文件自动识别自身角色。

**步骤 3 — 启动子 agent**

```
agent_open(
  name: "<role>-<feature-id>",
  prompt: "你是 <role>。读取 agents/<role>/SKILL.md，按其中定义的工作流程完成 <feature-id> 的全部工作。",
  fork_context: true
)
```

- `fork_context: true` 让子 agent 继承当前项目的完整上下文（instructions.md、harness/ 文件等），子 agent 通过 SESSION-HANDOFF 自动识别自身角色
- 在 `work/logs/log.json` 中追加一行编排日志：`{"timestamp":"<ISO 8601>","agent":"orchestrator","action":"agent_open","role":"<role>","feature":"<id>","detail":"启动子 agent"}`
- `agent_open` 立即返回 `agent_id`，子 agent 在后台异步运行

**步骤 4 — 等待完成**

```
agent_eval(agent_id: "<id>", block: true, timeout_ms: 3600000)
```

- `block: true` 阻塞等待子 agent 完成全部工作
- 超时时间设为 60 分钟（3600000ms），适用于大型功能实现
- 当收到 `<codewhale:subagent.done>` 事件时，读取摘要行确认子 agent 状态：
  - `"completed"` → 子 agent 正常完成，继续步骤 5
  - `"failed"` → 子 agent 执行失败，读取错误信息，判定是否可重试或需人工介入

**步骤 5 — 关闭子 agent**

```
agent_close(agent_id: "<id>")
```

释放子 agent 资源。在 `work/logs/log.json` 中追加一行：`{"timestamp":"<ISO 8601>","agent":"orchestrator","action":"agent_close","role":"<role>","feature":"<id>","detail":"子 agent 完成"}`

**步骤 6 — 读取交接信息**

重新读取 `harness/SESSION-HANDOFF.md`，获取子 agent 更新后的「下一个 Agent」信息。

**步骤 7 — 判定循环方向**

根据子 agent 的输出，确定下一步：

| 当前 agent | 结果 | 下一个 agent | 说明 |
|-----------|------|-------------|------|
| planner | 完成 BREAKDOWN + PLAN | implementer | 正常流程 |
| implementer | 全部单元 done | reviewer | 正常流程 |
| reviewer | L1/L2/L3 全部 PASS | （reviewer 自动归档，然后）planner | 功能完成，进入下一功能循环 |
| reviewer | 任一层 FAIL（FIX-QUEUE 非空） | implementer | 修复循环 |
| reviewer | 同功能退回 > 3 次 | **阻塞** | 停止循环，输出阻塞报告，等待人工介入 |
| 任意 | 子 agent 失败（status: failed） | 视情况重试或阻塞 | 读取错误原因后判定 |

**步骤 8 — 循环继续**

回到步骤 2，更新 SESSION-HANDOFF 指向下一个角色，继续循环。

**终止条件**：

- `feature_list.json` 中所有功能 `status` 均为 `"completed"` → 项目完成，输出完成报告
- 遇到阻塞项（同功能退回 > 3 次）→ 输出阻塞报告，含功能 ID、失败摘要、人类介入指引
- 用户主动中断

**串行执行约束**：

- 同一时间只允许一个子 agent 运行
- 必须等待 `agent_eval(block=true)` 返回后再执行 `agent_close`
- `agent_close` 完成后才能启动下一个 `agent_open`
- 禁止并行启动多个 agent_open（planner/implementer/reviewer 之间有严格依赖关系）

**上下文管理**：

- 编排者自身上下文较轻（只做调度和文件读取），预期可支撑多个功能循环
- 当上下文使用达到 ~60% 时，在当前功能循环完成后执行 `/compact` 压缩历史
- 压缩前确保 `SESSION-HANDOFF.md` 准确反映当前进度

### 每次会话结束

编排者模式下，会话结束前：
1. 确保 `harness/SESSION-HANDOFF.md` 已由最后执行的子 agent 更新
2. 更新 `harness/PROGRESS.md`
3. 更新 `harness/feature_list.json`（如状态有变化）
4. 运行 `flutter analyze && flutter test` 确认一致状态
5. 清理临时文件、调试代码
6. 提交所有已完成的工作

---

## 自动角色识别

<!-- 来源：L05 跨会话上下文。让 agent 在会话启动时自动知道自己该扮演谁。 -->

**每次会话开始时，按以下优先级确定你的角色：**

1. **用户显式指定**：用户在首条消息中明确说了"你是 initer" / "扮演 planner" / "以 reviewer 身份"等 → 使用用户指定的角色
2. **SESSION-HANDOFF.md 指定**：读取 `harness/SESSION-HANDOFF.md`，查找 "## 下一个 Agent" 节中的 `- **角色**：` 字段 → 使用该角色
3. **无法确定**：上述两者都缺失 → 进入**编排者模式**，启动 Agent 循环（详见上方「Agent 循环编排」节），自动推进功能开发

**确定角色后**：
- **编排者模式** → 按「Agent 循环编排」流程执行，通过子 agent 调度完成功能开发循环
- **具体角色**（planner / implementer / reviewer / initer）→ 读取对应的 `agents/<role>/SKILL.md`，按 SKILL 定义的工作流程执行，不跳过任何输入读取步骤

**角色切换规则**：
- **编排者模式下**：角色切换由编排者自动完成（通过 `agent_open` 启动不同角色的子 agent），无需人工干预
- **非编排者模式**（直接扮演具体角色时）：除用户显式要求外，不允许在同一次会话中切换角色；一个 agent 完成交付/交接后，会话就此结束

---

## 角色

<!-- 来源：L09 "干活和检查分开"、L11 多角色架构 -->

本项目使用四 agent 角色协作，你应只扮演被分配的角色：

- **initer**：环境初始化者。探测环境、生成 `tools/init.sh` 和 `tools/verify.sh`、验证开发环境就绪（`agents/initer/SKILL.md`）。独立 agent，必须在单独会话中运行，不参与功能循环。
- **planner**：选功能、标进度、出方案（`agents/planner/SKILL.md`）
- **implementer**：建模块、写代码、写测试、记决策（`agents/implementer/SKILL.md`）
- **reviewer**：三层验证、写修复单、归档（`agents/reviewer/SKILL.md`）

干活和检查必须是不同 agent，不允许自己评估自己的工作。

**执行流程**：initer（一次性）→ planner → implementer → reviewer → 下一个功能循环。

**编排者模式下**：由编排者通过 `agent_open` 以子 agent 形式启动各角色，每个子 agent 天然拥有独立上下文，避免角色污染。子 agent 之间、子 agent 与编排者之间严格隔离。

**非编排者模式**（直接扮演具体角色时）：必须新建独立对话启动该角色，不要在同一个对话中切换角色。

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
