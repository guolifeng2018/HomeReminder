# 模块进度 — core/common

<!-- 由 implementer 维护。追踪每个工作单元的实现和测试状态。 -->

---

## 基本信息

- **功能 ID**：F-01
- **模块名称**：core/common（通用模块）
- **最后更新**：2026-05-29

---

## 工作单元

| # | 单元 | 描述 | 状态 |
|---|------|------|------|
| 1 | 常量 app_constants.dart | 应用名称、预设分组、时间格式模板 | done |
| 2 | 枚举 enums.dart | ReminderStatus + ReminderFrequency | done |
| 3 | Group 模型 group_model.dart | Group 实体 + 序列化 | done |
| 4 | Reminder 模型 reminder_model.dart | Reminder 实体 + 枚举序列化 | done |
| 5 | DateFormatter | 自然语言口语时间解析 | done |
| 6 | StringSanitizer | 输入清洗 | done |
| 7 | PermissionManager | 抽象类 + Stub 实现 | done |
| 8 | Barrel file | common.dart 统一导出 | done |
| 9 | 单元测试 | 全部模型/工具/枚举测试 | done |
| 10 | 最终验证 | flutter analyze + flutter test | done |

---

## 测试覆盖率

| 测试文件 | 覆盖目标 | 状态 |
|---------|---------|------|
| test/unit/common/group_model_test.dart | Group 模型 | done |
| test/unit/common/reminder_model_test.dart | Reminder 模型 | done |
| test/unit/common/enums_test.dart | 枚举 | done |
| test/unit/common/date_formatter_test.dart | DateFormatter | done |
| test/unit/common/string_sanitizer_test.dart | StringSanitizer | done |
| test/unit/common/permission_manager_test.dart | PermissionManager | done |
| test/unit/common/app_constants_test.dart | 常量 | done |
