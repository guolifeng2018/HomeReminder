# 实现方案

<!-- 由 planner 填写。implementer 据此实现。 -->

---

## 基本信息

- **功能 ID**：F-03
- **功能名称**：Riverpod 状态管理 + 依赖注入

---

## 涉及模块

| 模块 | 变更类型 | 说明 |
|------|---------|------|
| src/core/config/ | **新建** | AppConfig 模型 + ModelDownloadStatus 枚举 |
| src/core/services/ | **新建** | ReminderService / NotificationService / VoiceService 抽象接口 + stub |
| src/core/providers/ | **新建** | 数据层 Provider + 服务 Provider + 配置 Provider |
| lib/main.dart | 验证/微调 | 已有 ProviderScope，验证无误即可 |
| test/unit/providers/ | **新建** | Provider 解析 + override + 状态切换测试 |

---

## 实现步骤

<!-- 按顺序排列 -->

### 步骤 1：AppConfig 模型 + ModelDownloadStatus 枚举

- **内容**：创建 `src/core/config/app_config.dart`，定义：
  ```dart
  enum ModelDownloadStatus { idle, downloading, completed, failed }

  class AppConfig {
    final bool isFirstLaunch;
    final ModelDownloadStatus modelDownloadStatus;
    const AppConfig({this.isFirstLaunch = true, this.modelDownloadStatus = ModelDownloadStatus.idle});
    AppConfig copyWith({bool? isFirstLaunch, ModelDownloadStatus? modelDownloadStatus});
  }
  ```
- **验收标准**：`cd src/core/config && dart analyze . 2>&1` 零 error/warning
- **涉及文件**：`src/core/config/app_config.dart`（新建）

### 步骤 2：Service 抽象接口 + stub 实现

- **内容**：创建三个 service 文件，每个包含：
  - 抽象类（方法签名预留，具体参数/返回值由后续模块补全）
  - Stub 实现类（所有方法 `throw UnimplementedError('F-03 stub')`）

  | 文件 | 抽象类 | Stub 类 | 说明 |
  |------|--------|---------|------|
  | `src/core/services/reminder_service.dart` | `ReminderService` | `StubReminderService` | 提醒相关：创建/更新/删除/时间解析（后续 F-05 实现） |
  | `src/core/services/notification_service.dart` | `NotificationService` | `StubNotificationService` | 通知推送：本地通知调度/取消（后续 F-06 实现） |
  | `src/core/services/voice_service.dart` | `VoiceService` | `StubVoiceService` | 语音识别：录音/ASR 识别（后续 F-10 实现） |

  抽象类方法示意（不强约束签名，implementer 可根据 Riverpod 惯例自行设计）：
  ```dart
  abstract class ReminderService {
    Future<void> scheduleReminder(Reminder reminder);
    Future<void> cancelReminder(int id);
  }
  abstract class NotificationService {
    Future<void> showNotification(String title, String body);
    Future<void> cancelAll();
  }
  abstract class VoiceService {
    Future<String> startListening();
    Future<void> stopListening();
  }
  ```
- **验收标准**：`cd src/core/services && dart analyze . 2>&1` 零 error/warning
- **涉及文件**：`src/core/services/reminder_service.dart`、`notification_service.dart`、`voice_service.dart`（新建 ×3）

### 步骤 3：数据库 Provider

- **内容**：创建 `src/core/providers/database_providers.dart`，定义三个 Provider：

  ```dart
  // 数据库实例 Provider（单例，dispose 时 close）
  final databaseProvider = Provider<AppDatabase>((ref) {
    final db = AppDatabase(NativeDatabase.memory()); // 开发阶段用内存，后续切换文件
    ref.onDispose(() => db.close());
    return db;
  });

  // Group Repository
  final groupRepositoryProvider = Provider<GroupRepository>((ref) {
    final db = ref.watch(databaseProvider);
    return GroupRepository(db);
  });

  // Reminder Repository
  final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
    final db = ref.watch(databaseProvider);
    return ReminderRepository(db);
  });
  ```

- **验收标准**：`cd src/core/providers && dart analyze . 2>&1` 零 error/warning
- **涉及文件**：`src/core/providers/database_providers.dart`（新建）
- **依赖**：F-02 导出的 `AppDatabase`、`GroupRepository`、`ReminderRepository`（import `../../database/database.dart`）

### 步骤 4：服务 Provider

- **内容**：创建 `src/core/providers/service_providers.dart`，定义三个 Provider：

  ```dart
  // 均默认注入 stub 实现，后续模块通过 ProviderScope.overrides 替换为真实实现
  final reminderServiceProvider = Provider<ReminderService>((ref) {
    return StubReminderService();
  });

  final notificationServiceProvider = Provider<NotificationService>((ref) {
    return StubNotificationService();
  });

  final voiceServiceProvider = Provider<VoiceService>((ref) {
    return StubVoiceService();
  });
  ```

  **重要**：annotate with `@visibleForTesting` or document that these providers are designed to be overridden when real implementations become available (F-05/F-06/F-10).

- **验收标准**：`cd src/core/providers && dart analyze . 2>&1` 零 error/warning
- **涉及文件**：`src/core/providers/service_providers.dart`（新建）
- **依赖**：#2（service 抽象 + stub）

### 步骤 5：AppConfig Provider

- **内容**：创建 `src/core/providers/app_config_provider.dart`：

  ```dart
  class AppConfigNotifier extends StateNotifier<AppConfig> {
    AppConfigNotifier() : super(const AppConfig());

    void setFirstLaunch(bool value) {
      state = state.copyWith(isFirstLaunch: value);
    }

    void setModelDownloadStatus(ModelDownloadStatus status) {
      state = state.copyWith(modelDownloadStatus: status);
    }
  }

  final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
    return AppConfigNotifier();
  });
  ```

  **默认值**：isFirstLaunch=true, modelDownloadStatus=ModelDownloadStatus.idle

- **验收标准**：`cd src/core/providers && dart analyze . 2>&1` 零 error/warning
- **涉及文件**：`src/core/providers/app_config_provider.dart`（新建）
- **依赖**：#1（AppConfig 模型）

### 步骤 6：main.dart 集成验证

- **内容**：检查 `lib/main.dart`，当前已有 `ProviderScope` 包裹 `HomeReminderApp`。确认：
  1. `flutter_riverpod` 已 import
  2. `ProviderScope` 为最外层 Widget
  3. `WidgetsFlutterBinding.ensureInitialized()` 在 `runApp` 之前调用

  如需初始化（如数据库路径），可添加 `initializeApp()` 函数，但 F-03 阶段数据库用内存模式，暂不需要。

- **验收标准**：`flutter analyze lib/ 2>&1` 零 error/warning
- **涉及文件**：`lib/main.dart`（检查，可能微调）

### 步骤 7：Provider 单元测试

- **内容**：创建 `test/unit/providers/` 目录，编写以下测试文件：

  **`provider_resolution_test.dart`** — 核心测试：
  ```dart
  // 创建 ProviderContainer，逐一读取 6 个 Provider（database/groupRepo/reminderRepo/
  // reminderService/notificationService/voiceService/appConfig），验证无异常抛出
  ```

  **`provider_override_test.dart`** — 替换测试：
  ```dart
  // 创建 mock ReminderService，通过 ProviderScope.overrides 注入，
  // 验证读取到的是 mock 而非 stub
  ```

  **`app_config_provider_test.dart`** — 配置测试：
  ```dart
  // 验证默认值 isFirstLaunch=true, modelDownloadStatus=idle
  // 验证 setFirstLaunch 状态切换
  // 验证 setModelDownloadStatus 各状态切换
  ```

- **验收标准**：`flutter test test/unit/providers/ 2>&1` 全部 PASS
- **涉及文件**：`test/unit/providers/provider_resolution_test.dart`、`provider_override_test.dart`、`app_config_provider_test.dart`（新建 ×3）
- **依赖**：#3, #4, #5, #6

### 步骤 8：依赖图无环检查

- **内容**：
  1. 运行 `grep -r 'import.*feature' src/core/` 确认空输出（core 不依赖 feature）
  2. 手动检查 Provider 依赖链：databaseProvider → groupRepositoryProvider/reminderRepositoryProvider，无逆向引用
  3. 服务 Provider 与数据库 Provider 之间无交叉依赖
  4. appConfigProvider 不依赖其他 Provider

- **验收标准**：
  ```bash
  grep -r 'import.*feature' src/core/ 2>&1 | test ! -s  # 空输出 = PASS
  ```
  人工确认 Provider 依赖图中无环

- **涉及文件**：无需新建，纯检查

---

## 依赖

<!-- 外部库、工具、或必须先完成的模块 -->

| 依赖 | 类型 | 说明 |
|------|------|------|
| flutter_riverpod | 外部库 | 已在 pubspec.yaml 声明（^2.6.1），使用 `riverpod` + `flutter_riverpod` |
| core/database (F-02) | 模块 | 提供 AppDatabase / GroupRepository / ReminderRepository 类型 |
| core/common (F-01) | 模块 | 提供 Group / Reminder / ReminderStatus 等模型（间接依赖，通过 F-02） |
| drift/native.dart | 外部库 | NativeDatabase.memory() 用于测试和开发阶段数据库 |

---

## 排除项

<!-- 明确本次不做，防止 overflow -->

1. **Service 真实实现**：留给 F-05（ReminderService）、F-06（NotificationService）、F-10（VoiceService）
2. **路由守卫集成**：appConfigProvider 的 isFirstLaunch 与 GoRouter redirect 联动属于 F-04
3. **持久化数据库路径**：F-03 用 NativeDatabase.memory()；文件路径数据库由 F-04 或各 feature 模块按需接入
4. **Widget/UI**：F-03 不创建任何 Widget
5. **F-01/F-02 代码修改**：已有 Repository 和模型的构造函数签名已适配 Provider 注入，无需修改
6. **barrel file**：F-03 的 Provider 文件不需要统一的 barrel export，各 Provider 按需被后续模块 import
