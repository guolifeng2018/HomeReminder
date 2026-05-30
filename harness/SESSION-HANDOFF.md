# 会话交接

---

## 下一个 Agent

- **角色**：planner
- **任务摘要**：开始 F-08（手动录入流程）功能规划
- **技能文件**：agents/planner/SKILL.md

---

## 仓库状态

- **已完成并验证**：F-00 ~ F-07
- **已重置未开始**：F-08 ~ F-20（status: pending，待重跑）
- **下一功能**：F-08

---

## 快速启动

1. 读取 `agents/planner/SKILL.md`
2. 确认 `harness/feature_list.json` 中 F-08 为第一个 pending 功能
3. 将 `templates/work/` 复制到 `work/`，制定 BREAKDOWN + PLAN
