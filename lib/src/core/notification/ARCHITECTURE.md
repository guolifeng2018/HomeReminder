# 模块架构

<!-- 由 implementer 填写。描述本模块的架构设计。 -->

---

## 模块概述

- **模块名**：core/notification
- **职责**：系统原生通知推送、到期提醒、通知点击负载处理、应用角标管理

---

## 对外接口

| 接口 | 签名 | 说明 |
|------|------|------|
| NotificationInitializer | `Future<void> ensureInitialized()` | 跨平台通知初始化（Android channel + iOS 权限） |
| NotificationContentBuilder | `AndroidNotificationDetails buildAndroid(...)` / `DarwinNotificationDetails buildDarwin(...)` | 构建平台通知内容（分组名+标题+内容渲染） |
| NotificationPayloadHandler | `static String encodePayload(int)` / `static int? decodePayload(String?)` | 通知点击 payload 序列化/反序列化 |
| BadgeManager | `Future<void> updateBadge(int, int)` | 应用角标更新 |
| NotificationServiceImpl | `Future<void> showNotification(...)` / `cancelAll()` / `cancelReminderNotification(int)` | 通知调度完整流程实现 |

---

## 内部结构

```
NotificationService (抽象接口，定义于 core/providers)
  └── NotificationServiceImpl
        ├── NotificationInitializer (初始化)
        ├── NotificationContentBuilder (内容)
        ├── NotificationPayloadHandler (payload)
        └── BadgeManager (角标)
```

---

## 依赖

| 依赖模块 | 用途 |
|---------|------|
| core/common | Reminder 数据模型、枚举 |
| core/providers | NotificationService 抽象接口 |
| flutter_local_notifications | 跨平台本地通知推送 |
| flutter_app_badger | 应用角标管理 |
