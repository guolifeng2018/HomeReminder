# 实现方案

<!-- 由 planner 填写。implementer 据此实现。 -->

---

## 基本信息

- **功能 ID**：F-01
- **功能名称**：core/common 通用模块
- **前置**：F-00（Flutter 工程脚手架）需先完成；本次方案含 F-00 补全步骤

---

## 涉及模块

| 模块 | 变更类型 | 说明 |
|------|---------|------|
| pubspec.yaml | 修改 | 添加 flutter_riverpod, drift, sqlite3_flutter_libs, flutter_local_notifications, go_router, record, path_provider, intl |
| analysis_options.yaml | 修改 | 配置严格 lint 规则：禁止 print/debugger/TODO，启用类型安全全开 |
| lib/main.dart | 新建 | ProviderScope 包裹 MaterialApp，应用入口 |
| src/core/common/ | 新建 | 通用模块：常量、数据模型、工具类、权限管理、barrel file |
| src/core/database/ | 新建目录 | 占位（F-02 使用） |
| src/core/voice/ | 新建目录 | 占位（F-04 使用） |
| src/core/reminder/ | 新建目录 | 占位（F-06 使用） |
| src/core/notification/ | 新建目录 | 占位（F-08 使用） |
| src/feature/home/ | 新建目录 | 占位（F-05 使用） |
| src/feature/voice_input/ | 新建目录 | 占位（F-07 使用） |
| src/feature/group_manage/ | 新建目录 | 占位（F-09 使用） |
| src/feature/cleanup/ | 新建目录 | 占位（F-12 使用） |
| test/unit/common/ | 新建目录 | F-01 单元测试 |

---

## 实现步骤

<!-- 按顺序排列 -->

### 步骤 0：F-00 补全（前置）

- **内容**：
  1. 修改 `pubspec.yaml`，添加所有必需依赖（版本号明确，使用当前 pub.dev 最新兼容版本）：
     - `flutter_riverpod: ^2.6.1`
     - `drift: ^2.22.0`
     - `sqlite3_flutter_libs: ^0.5.24`
     - `flutter_local_notifications: ^18.0.0`
     - `go_router: ^14.6.2`
     - `record: ^5.2.0`
     - `path_provider: ^2.1.4`
     - `intl: ^0.19.0`
     - dev_dependency: `drift_dev: ^2.22.0`, `build_runner: ^2.4.12`
  2. 运行 `flutter pub get` 确认依赖下载成功
  3. 创建 `src/` 完整目录结构（见「涉及模块」表，每个模块含 `code/` 子目录 + `ARCHITECTURE.md`, `CONSTRAINTS.md`, `PROGRESS.md` 占位文件）
  4. 修改 `analysis_options.yaml`：启用 `avoid_print: true`, `no_debugger: true`，添加 `strict-inference: true`, `strict-raw-types: true`，禁止 TODO 注释遗留
  5. 创建 `lib/main.dart`：ProviderScope 包裹 MaterialApp，首页占位 Scaffold（显示「居净清单」标题）
  6. 创建 `test/unit/common/` 和 `test/unit/database/` 目录
  7. 标记 F-00 为 `completed`（`harness/feature_list.json`）
- **验收标准**：
  ```bash
  flutter pub get 2>&1 | grep -q 'exit code 0' || flutter pub get
  flutter analyze  # 零 warning
  grep -c 'flutter_riverpod\|drift\|flutter_local_notifications\|go_router\|record\|path_provider\|intl' pubspec.yaml  # ≥7
  ls -d src/core/*/code/ src/feature/*/code/ test/unit/common/  # 全部存在
  ```
- **涉及文件**：`pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`, `src/` (目录创建)

### 步骤 1：常量与枚举定义

- **内容**：
  1. 创建 `src/core/common/code/constants/app_constants.dart`
     - `const String appName = '居净清单'`
     - `const List<Map<String, dynamic>> defaultGroups = [...]`（6 组：客厅/卧室/厨房/冰箱/扫地机/地面，每组含 id, name, icon, is_preset, sort_order）
     - 时间格式模板常量（如 `'yyyy-MM-dd HH:mm'`, `'MM月dd日 HH:mm'` 等）
  2. 创建 `src/core/common/code/models/enums.dart`
     - `enum ReminderStatus { pending, overdue, completed, dismissed }`（含 `fromString` / `displayName` 扩展）
     - `enum ReminderFrequency { once, daily, weekly, biweekly, monthly }`（含 `fromString` / `displayName` / `duration` 扩展）
- **验收标准**：
  ```bash
  dart analyze lib/src/core/common/code/constants/ lib/src/core/common/code/models/enums.dart
  # 零 issue
  ```
- **涉及文件**：`src/core/common/code/constants/app_constants.dart`, `src/core/common/code/models/enums.dart`

### 步骤 2：Group 数据模型

- **内容**：
  创建 `src/core/common/code/models/group_model.dart`
  - `Group` 类（immutable，使用 `@immutable` 注解）
  - 字段：`int id`, `String name`, `String? icon`, `bool isPreset`, `int sortOrder`, `DateTime createdAt`
  - 方法：`factory Group.fromJson(Map<String, dynamic>)`, `Map<String, dynamic> toJson()`, `factory Group.fromMap(Map<String, dynamic>)`, `Map<String, dynamic> toMap()`, `Group copyWith({...})`, `operator ==`, `hashCode`, `toString`
  - 序列化健壮性：缺失可选字段用默认值，类型不匹配不抛异常（返回 null 或默认值）
- **验收标准**：
  ```bash
  dart analyze lib/src/core/common/code/models/group_model.dart  # 零 issue
  ```
- **涉及文件**：`src/core/common/code/models/group_model.dart`

### 步骤 3：Reminder 数据模型

- **内容**：
  创建 `src/core/common/code/models/reminder_model.dart`
  - `Reminder` 类（immutable）
  - 字段：`int id`, `int groupId`, `String title`, `String? content`, `DateTime scheduledAt`, `ReminderStatus status`, `ReminderFrequency frequency`, `DateTime createdAt`, `DateTime? updatedAt`
  - 方法：`factory Reminder.fromJson(...)`, `toJson()`, `fromMap(...)`, `toMap()`, `copyWith(...)`, `==`, `hashCode`, `toString`
  - 枚举字段序列化为字符串 `status.name` / `frequency.name`，反序列化用 `ReminderStatus.fromString`
  - 时间字段在 JSON 中用 ISO 8601 字符串，在 Map 中用 millisecondsSinceEpoch
- **验收标准**：
  ```bash
  dart analyze lib/src/core/common/code/models/reminder_model.dart  # 零 issue
  ```
- **涉及文件**：`src/core/common/code/models/reminder_model.dart`

### 步骤 4：DateFormatter 时间解析

- **内容**：
  创建 `src/core/common/code/utils/date_formatter.dart`
  - 类方法：`static DateTime? parseNaturalLanguage(String input, {DateTime? referenceDate})`
  - 不引入 `intl` 以外的外部依赖
  - 解析策略：正则匹配 → 提取时间关键词 → 计算目标 DateTime
  - 必须覆盖的口语表达（≥15 条）：
    1. "今天下午三点" → 今天 15:00
    2. "明天上午九点" → 明天 09:00
    3. "后天" → 后天 09:00（默认）
    4. "下周一" → 下周一 09:00
    5. "下周" → 7 天后 09:00
    6. "半个月后" → 15 天后 09:00
    7. "一个月后" → 30 天后 09:00
    8. "每三天" → 3 天后 09:00（首次触发）
    9. "每周五" → 本周/下周五 09:00
    10. "每天晚上八点" → 今天/明天 20:00
    11. "明天中午" → 明天 12:00
    12. "下个月五号" → 下个月 5 号 09:00
    13. "大后天" → 3 天后 09:00
    14. "本周日" → 本周日 09:00
    15. "半小时后" → now + 30min
  - 边界处理：闰年 2 月 29 日、月末 31 日溢出、上午12点=0:00、下午12点=12:00、不可解析返回 null
- **验收标准**：
  ```bash
  dart analyze lib/src/core/common/code/utils/date_formatter.dart  # 零 issue
  ```
- **涉及文件**：`src/core/common/code/utils/date_formatter.dart`

### 步骤 5：StringSanitizer 字符串清洗

- **内容**：
  创建 `src/core/common/code/utils/string_sanitizer.dart`
  - `static String sanitize(String? input, {int maxLength = 500})`
  - 处理逻辑：
    1. null → 返回空字符串 `''`
    2. trim 首尾空白
    3. 连续空白字符合并为一个空格（正则 `\s+` → ` `）
    4. 移除控制字符（0x00-0x1F, 0x7F-0x9F，保留换行 `\n`）
    5. 移除零宽字符（U+200B, U+200C, U+200D, U+FEFF）
    6. 截断超长字符串（> maxLength）
    7. 可选：`static bool isEmpty(String? input)` / `static bool isNotEmpty(String? input)`
- **验收标准**：
  ```bash
  dart analyze lib/src/core/common/code/utils/string_sanitizer.dart  # 零 issue
  ```
- **涉及文件**：`src/core/common/code/utils/string_sanitizer.dart`

### 步骤 6：PermissionManager 权限管理

- **内容**：
  1. 创建 `src/core/common/code/permissions/permission_manager.dart`
     - `enum PermissionType { microphone, notification, storage }`
     - `enum PermissionStatus { granted, denied, permanentlyDenied, restricted, unknown }`
     - `abstract class PermissionManager` 含抽象方法：
       - `Future<PermissionStatus> checkPermission(PermissionType type)`
       - `Future<PermissionStatus> requestPermission(PermissionType type)`
       - `Future<bool> openSettings()`
  2. 创建 `src/core/common/code/permissions/permission_manager_stub.dart`
     - `class PermissionManagerStub extends PermissionManager`：全部返回 `PermissionStatus.granted`，供测试使用
     - 注释标注：`// STUB — 真实实现见 F-10 (Android) / F-11 (iOS)`
- **验收标准**：
  ```bash
  dart analyze lib/src/core/common/code/permissions/  # 零 issue
  ```
- **涉及文件**：
  `src/core/common/code/permissions/permission_manager.dart`,
  `src/core/common/code/permissions/permission_manager_stub.dart`

### 步骤 7：Barrel file

- **内容**：
  创建 `src/core/common/common.dart`，统一导出所有公开接口：
  ```dart
  export 'code/constants/app_constants.dart';
  export 'code/models/enums.dart';
  export 'code/models/group_model.dart';
  export 'code/models/reminder_model.dart';
  export 'code/utils/date_formatter.dart';
  export 'code/utils/string_sanitizer.dart';
  export 'code/permissions/permission_manager.dart';
  export 'code/permissions/permission_manager_stub.dart';
  ```
- **验收标准**：
  ```bash
  dart analyze lib/src/core/common/common.dart  # 零 issue
  # 验证无循环 import
  dart analyze lib/src/core/common/  # 零 issue
  ```
- **涉及文件**：`src/core/common/common.dart`

### 步骤 8：单元测试

- **内容**：
  在 `test/unit/common/` 下创建以下测试文件：

  **`app_constants_test.dart`**
  - APP_NAME 非空且等于 '居净清单'
  - DEFAULT_GROUPS 长度为 6
  - 每组含 id, name, is_preset（全部 true）, sort_order 字段
  - sort_order 无重复

  **`enums_test.dart`**
  - ReminderStatus 4 个值（pending, overdue, completed, dismissed）
  - ReminderFrequency 5 个值（once, daily, weekly, biweekly, monthly）
  - `fromString` 大小写不敏感、未知值返回默认
  - `toJson` / `fromJson` 往返正确

  **`group_model_test.dart`**
  - `fromJson` / `toJson` 往返一致
  - `fromMap` / `toMap` 往返一致
  - `copyWith` 部分更新、未指定字段保持不变
  - `==` 相同字段返回 true、不同字段返回 false
  - `hashCode` 相同对象一致
  - 可选字段 `icon` 为 null 时序列化不含该字段

  **`reminder_model_test.dart`**
  - 同上所有模型测试
  - status/frequency 枚举序列化：JSON 中为字符串，Map 中为 index
  - `updatedAt` 为 null 时正确序列化

  **`date_formatter_test.dart`**
  - ≥15 条口语时间解析测试（每条含输入字符串、预期 DateTime）
  - 边界：闰年 2024-02-29、月末 2024-01-31 加一个月 → 2024-02-29
  - 不可解析输入返回 null（"随便什么时候"、"abc123"、空字符串）
  - `referenceDate` 参数生效验证

  **`string_sanitizer_test.dart`**
  - null → `''`
  - 空字符串 → `''`
  - 前后空白 trim
  - 连续空格合并（"hello    world" → "hello world"）
  - 控制字符移除
  - 超长截断（501 字符 → 500 字符）
  - 零宽字符移除
  - `isEmpty` / `isNotEmpty` 方法正确

  **`permission_manager_test.dart`**
  - Stub.checkPermission 全部返回 granted
  - Stub.requestPermission 全部返回 granted
  - Stub.openSettings 返回 true
  - PermissionType 包含 3 项
  - PermissionStatus 包含 5 项

- **验收标准**：
  ```bash
  flutter test test/unit/common/  # 全部通过（≥7 个 test 文件）
  ```
- **涉及文件**：`test/unit/common/*_test.dart`（7 个文件）

### 步骤 9：最终验证

- **内容**：
  1. 静态分析
  2. 单元测试全量运行
  3. 依赖方向检查（common 不应 import feature 层）
- **验收标准**：
  ```bash
  flutter analyze                         # 零 warning
  flutter test test/unit/common/          # 全部通过
  grep -r 'import.*feature' lib/src/core/common/  # 返回空（无匹配）
  ```
- **涉及文件**：全部

---

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| intl | 外部库 (pub) | DateFormatter 使用 DateFormat 格式化时间 |
| Flutter SDK | 框架 | 基础 Dart/Flutter 类型支持 |
| F-00 Flutter 工程脚手架 | 模块 | pubspec.yaml 配置 + src/ 目录结构（本方案步骤 0 补全） |

---

## 排除项

<!-- 明确本次不做，防止 overflow -->

1. **不实现权限原生方法通道**：PermissionManager 只提供抽象接口 + Stub，真实 Android（F-10）/ iOS（F-11）平台实现在后续功能
2. **不接入 ASR/LLM SDK**：SenseVoice-Tiny / Qwen-140M 属于 F-04 语音模块
3. **不实现 Drift 数据库**：数据库表定义、DAO、Repository 属于 F-02
4. **不实现 Riverpod Provider**：Provider 注册和依赖注入属于 F-03
5. **不实现 UI**：所有 Widget、页面、路由属于 F-05~F-09 feature 模块
6. **不引入 `flutter_riverpod` 到 common 层**：common 是纯 Dart 层，Provider 注册在 F-03@main.dart
7. **不引入 `intl` 以外的外部依赖**：保持 common 层最小化
