# docs/ — 项目文档

> 人类维护的长篇文档。agent 可读取参考，但不写入。

| 文件 | 谁写 | 说明 |
|------|------|------|
| `README.md` | 人 | 项目概览：这是什么项目、怎么跑、怎么测 |
| `architecture.md` | 人 | 系统架构文档：模块职责、数据流、技术选型理由 |
| `conventions.md` | 人 | 编码规范与约定：命名、目录、git 提交、code review 流程 |
| `task-breakdown/overview.md` | 人 | 全局任务拆分全貌：所有功能的依赖拓扑、执行顺序 |

## 与 harness/ 的分工

```
docs/         人写人读   知识沉淀（架构设计、规范约定）
harness/      agent 写  工作状态（进度、决策、交接、功能清单）
```

人把设计意图写入 `docs/`，agent 在执行中更新 `harness/`。人通过 `harness/` 文件观察 agent 的进展。
