# 功能拆分

<!-- 由 planner 填写。implementer 据此分配工作单元。 -->

---

## 基本信息

- **功能 ID**：F-03
- **功能名称**：Riverpod 状态管理 + 依赖注入
- **涉及模块**：core（全模块级 Provider 注册）

---

## 工作单元

<!-- 每个单元 = 单一行为 + 可执行验证命令 + 依赖关系 -->

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| 1 | AppConfig 模型 | 定义 `AppConfig` 数据类（isFirstLaunch: bool, modelDownloadStatus: ModelDownloadStatus）和 `ModelDownloadStatus` 枚举（idle/downloading/completed/failed），提供 `copyWith` | `cd src/core/config && dart analyze . 2>&1` | 无 | pending |
| 2 | Service 抽象接口 + stub | 创建三个抽象类：`ReminderService`（抽象方法待 F-05 定义）、`NotificationService`（抽象方法待 F-06 定义）、`VoiceService`（抽象方法待 F-10 定义），每个附带一个 `Stub*Service` 实现（所有方法 throw UnimplementedError） | `cd src/core/services && dart analyze . 2>&1` | 无 | pending |
| 3 | 数据库 Provider | 创建 `databaseProvider`（Provider<AppDatabase> 异步初始化，NativeDatabase 内存模式用于测试/开发）、`groupRepositoryProvider`（Provider<GroupRepository>）、`reminderRepositoryProvider`（Provider<ReminderRepository>），后两者依赖 databaseProvider | `cd src/core/providers && dart analyze . 2>&1` | F-02（已完成） | pending |
| 4 | 服务 Provider | 创建 `reminderServiceProvider`（Provider<ReminderService>，默认注入 StubReminderService）、`notificationServiceProvider`（Provider<NotificationService>，默认注入 StubNotificationService）、`voiceServiceProvider`（Provider<VoiceService>，默认注入 StubVoiceService），均声明为可 override | `cd src/core/providers && dart analyze . 2>&1` | #2 | pending |
| 5 | AppConfig Provider | 创建 `AppConfigNotifier`（StateNotifier<AppConfig>），`appConfigProvider`（StateNotifierProvider），提供 `setFirstLaunch(bool)` / `setModelDownloadStatus(ModelDownloadStatus)` 方法，默认值：isFirstLaunch=true, modelDownloadStatus=idle | `cd src/core/providers && dart analyze . 2>&1` | #1 | pending |
| 6 | main.dart 集成验证 | 确认 `main.dart` 中 `ProviderScope` 正确包裹 `HomeReminderApp`（已就绪），验证所有 Provider 文件在 `flutter analyze` 下无报错。如需要，添加顶层 `initializeApp` 初始化函数 | `flutter analyze lib/ 2>&1` | #3, #4, #5 | pending |
| 7 | Provider 单元测试 | 创建 `test/unit/providers/` 目录，编写测试：① 所有 6 个 Provider 可正常 resolve（无 ProviderNotFoundException）；② `ProviderOverride` 替换 stub→mock 验证；③ `appConfigProvider` 默认值 isFirstLaunch=true, modelDownloadStatus=ModelDownloadStatus.idle；④ `appConfigProvider` setModelDownloadStatus 状态切换 | `flutter test test/unit/providers/ 2>&1` | #3, #4, #5, #6 | pending |
| 8 | 依赖图无环检查 | 手动检查 import 链：确认 `src/core/` 下所有文件无 `import.*feature` 反向依赖，Provider 依赖方向为 databaseProvider → repositoryProvider，无循环 Provider 依赖（A depends on B depends on A） | `grep -r 'import.*feature' src/core/ 2>&1 \| test \! -s`（空输出=通过） | #3, #4, #5 | pending |

---

## 依赖拓扑

```
#1 (AppConfig 模型) ──────────────┐
                                   ├──→ #5 (AppConfig Provider) ──┐
#2 (Service 抽象 + stub) ──→ #4 (服务 Provider) ──────────────┤
                                                                   ├──→ #6 (main.dart 集成) ──→ #7 (单元测试)
#3 (数据库 Provider) ─────────────────────────────────────────┤
                                                                   │
                                                           #8 (依赖图检查) ← 全部
```

**并行建议**：#1 和 #2 无依赖关系，可并行启动。

---

## 排除项

<!-- 本次明确不做的内容，防止 implementer overreach -->

1. **不做 Service 的具体实现**：ReminderService / NotificationService / VoiceService 仅定义抽象接口 + stub，具体逻辑留给 F-05（core/reminder）、F-06（core/notification）、F-10（core/voice）
2. **不做路由集成**：Provider 与 GoRouter 的联动（路由守卫 isFirstLaunch）属于 F-04 范围
3. **不做原生数据库初始化**：databaseProvider 在 F-03 阶段使用 `NativeDatabase.memory()` 或项目路径下的 SQLite 文件，不做平台特定路径适配（path_provider 集成留给各 feature 模块）
4. **不做 UI**：F-03 是纯 core 层 Provider 注册，不涉及任何 Widget/Page
5. **不修改 F-01/F-02 已有代码**：除非需要适配 Provider 注入（如 Repository 构造函数签名已就绪，无需改动）
