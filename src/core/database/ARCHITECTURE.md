# 模块架构 — core/database

## 模块概述

- **模块名**：core/database（数据库模块）
- **职责**：Drift(SQLite) 数据库定义、分组/提醒 CRUD Repository、数据转换层

---

## 对外接口

| 接口 | 签名 | 说明 |
|------|------|------|
| AppDatabase | `@DriftDatabase(tables: [Groups, Reminders])` | Drift 数据库实例，持有 QueryExecutor |
| GroupRepository | 构造接受 `AppDatabase` | 分组表 CRUD + 预设分组初始化 |
| ReminderRepository | 构造接受 `AppDatabase` | 提醒表 CRUD + 状态批量更新 + 日期范围查询 |

---

## 内部结构

```
code/
├── database.dart               # Drift 表定义（Groups, Reminders）+ AppDatabase + 注解
├── database.g.dart              # build_runner 自动生成
├── group_repository.dart        # GroupRepository（分组 CRUD）
└── reminder_repository.dart     # ReminderRepository（提醒 CRUD）

database.dart                     # Barrel file 统一导出
```

---

## 依赖

| 依赖模块 | 用途 |
|---------|------|
| core/common | Group/Reminder 模型、枚举、DEFAULT_GROUPS 常量 |
| drift | SQLite ORM（类型安全查询） |
| sqlite3_flutter_libs | SQLite 原生库 |
