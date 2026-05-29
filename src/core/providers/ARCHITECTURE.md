# 模块架构

<!-- 由 implementer 填写。描述本模块的架构设计。 -->

---

## 模块概述

- **模块名**：core/providers
- **职责**：Riverpod 状态管理 + 依赖注入，提供数据层 Provider、服务层 Provider、配置 Provider 的全局注册

---

## 对外接口

| 接口 | 签名 | 说明 |
|------|------|------|
| databaseProvider | `Provider<AppDatabase>` | Drift AppDatabase 实例（内存模式） |
| groupRepositoryProvider | `Provider<GroupRepository>` | 分组数据仓库 |
| reminderRepositoryProvider | `Provider<ReminderRepository>` | 提醒数据仓库 |
| reminderServiceProvider | `Provider<ReminderService>` | 提醒服务（stub，可 override） |
| notificationServiceProvider | `Provider<NotificationService>` | 通知服务（stub，可 override） |
| voiceServiceProvider | `Provider<VoiceService>` | 语音服务（stub，可 override） |
| appConfigProvider | `StateNotifierProvider<AppConfigNotifier, AppConfig>` | 应用全局配置状态 |

---

## 内部结构

```
code/
├── app_config.dart               # AppConfig 模型 + ModelDownloadStatus 枚举
├── app_config_provider.dart      # AppConfigNotifier + appConfigProvider
├── database_providers.dart       # databaseProvider / groupRepositoryProvider / reminderRepositoryProvider
├── service_providers.dart        # reminderServiceProvider / notificationServiceProvider / voiceServiceProvider
├── reminder_service.dart         # ReminderService 抽象 + StubReminderService
├── notification_service.dart     # NotificationService 抽象 + StubNotificationService
└── voice_service.dart            # VoiceService 抽象 + StubVoiceService

providers.dart                    # Barrel file 统一导出
```

---

## 依赖

| 依赖模块 | 用途 |
|---------|------|
| core/database (F-02) | AppDatabase、GroupRepository、ReminderRepository 类型 |
| core/common (F-01) | Group、Reminder、ReminderStatus 等数据模型（间接通过 F-02） |
| flutter_riverpod | Provider / StateNotifierProvider 框架 |
| drift/native.dart | NativeDatabase.memory() 测试/开发数据库 |
