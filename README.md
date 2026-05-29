# HomeReminder — Harness Engineering 框架

> 基于 [Learn Harness Engineering](https://walkinglabs.github.io/learn-harness-engineering/) 课程构建的 AI Agent 工程化协作框架。

## 这是什么

Harness Engineering 的核心思想：**模型权重之外的一切工程基础设施，决定了模型能力能被发挥多少**。

本项目不是一个具体的应用程序——它是一个**让 AI coding agent 能可靠完成长周期任务的协作系统**。通过三 agent 角色（planner、implementer、reviewer）、结构化模板和验证流程，将 agent 从"不可靠"变为"可靠"。

## 快速开始

```bash
# 阅读框架设计
cat 描述.md

# 了解 agent 协作规则
cat .deepseek/instructions.md

# 查看各目录说明
cat harness/README.md
cat docs/README.md
```

## 目录地图

```
HomeReminder/
├── 描述.md                  # 框架设计文档（从这里开始）
├── .deepseek/instructions.md # agent 着陆页（自动注入）
├── harness/                  # agent 工作状态（进度、决策、约束）
├── agents/                   # 三角色技能定义
│   ├── planner/SKILL.md      # 调度者：选功能、定方案
│   ├── implementer/SKILL.md  # 实现者：写代码、写测试
│   └── reviewer/SKILL.md     # 验证者：三层验证、归档
├── templates/                # 项目模板（work + src）
├── tools/                    # 全局工具脚本
├── docs/                     # 人类维护的架构文档
└── test/                     # 三层测试目录
```

## 三角色协作

```
planner（选功能 → 定方案）
    │
    ▼
implementer（写代码 → 写测试 → 记决策）
    │
    ▼
reviewer（L1 静态 → L2 运行时 → L3 系统级）
    │
    ▼
归档 history/ → 下一个功能
```

每次角色切换必须新建独立对话，干活和检查严格分开。

## 参考

- [OpenAI: Harness Engineering](https://openai.com/index/harness-engineering/)
- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Anthropic: Harness Design for Long-Running App Development](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Learn Harness Engineering](https://walkinglabs.github.io/learn-harness-engineering/)
