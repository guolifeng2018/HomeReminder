# 会话交接

---

## 下一个 Agent

- **角色**：reviewer
- **任务摘要**：三层验证 F-08 交付物
- **技能文件**：agents/reviewer/SKILL.md

---

## 仓库状态

- **已完成并验证**：F-00 ~ F-07
- **当前 pending_review**：F-08（手动录入流程）
- **下一 pending**：F-09（模型下载管理）

---

## 快速启动

1. 读取 `agents/reviewer/SKILL.md`
2. 读取 `harness/CONSTRAINTS.md` 和 `harness/ARCHITECTURE.md`
3. 验证 `lib/src/router/code/app_router.dart`（/add 路由 → ReminderFormPage）
4. 验证 `lib/src/feature/home/code/home_fab.dart`（onAdd/onVoice 回调）
5. 验证 `lib/src/feature/home/code/home_page.dart`（onTap await + invalidate）
6. 运行 `flutter analyze` + `flutter test test/unit/home/`
7. 检查 `work/implementer/DECISIONS.md` 和 `work/planner/BREAKDOWN.md`
