# 模块架构 — core/reminder

---

## 模块概述

- **模块名**：core/reminder
- **职责**：口语时间解析、定时调度计算、推迟逻辑、重试机制，以及 ReminderService 集成

---

## 对外接口

| 接口 | 签名 | 说明 |
|------|------|------|
| SpokenTimeParser | `static DateTime? parse(String, {DateTime? referenceDate})` | ≥20 种口语模式→DateTime |
| ReminderScheduler | `DateTime? nextTriggerTime(...)` / `Future<List<Reminder>> findOverdue(...)` | 重复调度计算 + 过期扫描 |
| PostponeLogic | `static DateTime postpone(...)` | 1h/3h/明天/自定义推迟 |
| RetryPolicy | `static DateTime? nextRetryTime(int, DateTime)` | 3 次指数退避 5/15/45min |
| ReminderServiceImpl | `implements ReminderService` | 整合以上 + Repository 注入 |

---

## 内部结构

```
SpokenTimeParser ──┐
ReminderScheduler ─┤
PostponeLogic ─────┼──→ ReminderServiceImpl ──→ ReminderService (interface)
RetryPolicy ───────┘
                         │
                         ├── ReminderRepository
                         └── GroupRepository
```

---

## 依赖

| 依赖模块 | 用途 |
|---------|------|
| core/common (F-01) | Reminder 模型、ReminderStatus/ReminderFrequency 枚举 |
| core/database (F-02) | ReminderRepository、GroupRepository |
| core/providers (F-03) | ReminderService 抽象接口、databaseProvider |
| flutter_riverpod | Provider 依赖注入 |
