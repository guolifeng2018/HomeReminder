# 模块进度

<!-- 由 implementer 填写。追踪本模块的开发进度。 -->

---

## 基本信息

- **功能 ID**：F-03
- **模块名**：core/providers
- **最后更新**：2026-05-29

---

## 测试覆盖率目标

- **Unit**：>= 80%（覆盖所有 Provider resolve / override / 状态切换）

---

## 工作单元

| # | 单元名称 | 状态 | 完成日期 |
|---|---------|------|---------|
| 1 | AppConfig 模型 + ModelDownloadStatus 枚举 | done | 2026-05-29 |
| 2 | Service 抽象接口 + stub 实现 | done | 2026-05-29 |
| 3 | 数据库 Provider（databaseProvider / groupRepositoryProvider / reminderRepositoryProvider） | done | 2026-05-29 |
| 4 | 服务 Provider（reminderServiceProvider / notificationServiceProvider / voiceServiceProvider） | done | 2026-05-29 |
| 5 | AppConfig Provider（AppConfigNotifier + appConfigProvider） | done | 2026-05-29 |
| 6 | main.dart 集成验证 | done | 2026-05-29 |
| 7 | Provider 单元测试（resolve / override / 状态切换） | done | 2026-05-29 |
| 8 | 依赖图无环检查 | done | 2026-05-29 |

---

## 修复单元

<!-- reviewer 退回后追加的修复项 -->

| # | 修复项 | 来源 | 状态 | 完成日期 |
|---|--------|------|------|---------|
| - | - | - | - | - |

---

## 阻塞项

| 问题 | 严重程度 | 依赖 |
|------|---------|------|
| - | - | - |
