# harness/ — Harness 核心文件

> agent 的工作状态层。所有文件由 agent 读写，人类只做初始引导（填 feature_list、设约束）。

| 文件 | 类型 | 谁写 | 说明 |
|------|------|------|------|
| `ARCHITECTURE.md` | 指令 | agent | 项目级架构总览：技术栈、模块划分、依赖方向、关键设计决策 |
| `CONSTRAINTS.md` | 指令 | 人（初始） | 全局硬约束：禁止操作、强制规范，agent 不可修改 |
| `PROGRESS.md` | 状态 | planner | 全局进度：当前功能状态、完成率、已知阻塞项 |
| `feature_list.json` | 状态 | 人（初始） → planner（更新） | 功能清单 + 验收标准：三元组（行为描述、验证命令、当前状态） |
| `SESSION-HANDOFF.md` | 状态 | agent | 长会话交接：上一个会话做了什么、卡在哪、下一步做什么 |
| `EVALUATOR-RUBRIC.md` | 反馈 | 人（初始） | 六维度评审评分标准，agent 不可修改 |
| `decisions/` | 指令 | implementer | 项目级架构决策记录 (ADR)，文件命名 `{feature-id}_{module-name}_{decision-summary}.md` |

## agent 启动顺序

1. 读 `CONSTRAINTS.md` — 先搞清楚什么绝对不能做
2. 读 `ARCHITECTURE.md` — 理解项目是什么、怎么组织的
3. 读 `PROGRESS.md` — 知道现在做到哪了
4. 读 `feature_list.json` — 确认下一步该做什么
5. 读 `SESSION-HANDOFF.md` — 如果有未完成的工作，从这里接上
