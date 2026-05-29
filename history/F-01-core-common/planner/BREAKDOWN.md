# 功能拆分

<!-- 由 planner 填写。implementer 据此分配工作单元。 -->

---

## 基本信息

- **功能 ID**：F-01
- **功能名称**：core/common 通用模块
- **涉及模块**：core/common（新建）、pubspec.yaml（修改）、analysis_options.yaml（修改）、lib/main.dart（新建）、src/ 目录结构（新建）

---

## 前置说明

F-00（Flutter 工程脚手架）状态为 `in_progress`，但 pubspec.yaml 仍为默认脚手架、`src/` 和 `lib/` 无代码、缺失全部业务依赖。**F-00 的剩余工作作为 F-01 的前置工作单元 #1**，implementer 需先完成 F-00 后标记其 `completed`，再继续 F-01。

---

## 工作单元

<!-- 每个单元 = 单一行为 + 可执行验证命令 + 依赖关系 -->

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| 1 | F-00 前置补全 | 1) pubspec.yaml 添加全部依赖（flutter_riverpod, drift, sqlite3_flutter_libs, flutter_local_notifications, go_router, record, path_provider, intl）；2) 创建 src/core/{common,database,voice,reminder,notification}/code/ 和 src/feature/{home,voice_input,group_manage,cleanup}/code/ 目录结构；3) 创建 src/core/common/{ARCHITECTURE,CONSTRAINTS,PROGRESS}.md 占位；4) analysis_options.yaml 配置禁止 print/debugger 警告、启用 strict-inference/type-safe rules；5) 创建 lib/main.dart（ProviderScope 包裹 MaterialApp）；6) 创建 test/unit/common/ 目录 | `flutter pub get` 无报错 && `flutter analyze` 零 warning && `grep -c 'flutter_riverpod\|drift\|flutter_local_notifications\|go_router\|record\|path_provider\|intl' pubspec.yaml` ≥7 && `ls -d src/core/*/code src/feature/*/code test/unit/common` 全部存在 | 无 | pending |
| 2 | 常量定义 | 创建 `src/core/common/code/constants/app_constants.dart`：APP_NAME='居净清单'、DEFAULT_GROUPS 预设分组列表（6 组：客厅/卧室/厨房/冰箱/扫地机/地面，每组含 id/name/icon/sort_order）、时间格式模板常量 | `dart analyze lib/src/core/common/code/constants/` 零 issue | #1 | pending |
| 3 | 枚举定义 | 创建 `src/core/common/code/models/enums.dart`：ReminderStatus（pending/overdue/completed/dismissed）、ReminderFrequency（once/daily/weekly/biweekly/monthly） | `dart analyze lib/src/core/common/code/models/enums.dart` 零 issue && 枚举值数量正确（4+5） | #1 | pending |
| 4 | Group 数据模型 | 创建 `src/core/common/code/models/group_model.dart`：Group 实体（id/int, name/String, icon/String?, is_preset/bool, sort_order/int, created_at/DateTime）含 fromJson/toJson/fromMap/toMap/copyWith/==/hashCode/toString | `dart analyze lib/src/core/common/code/models/group_model.dart` 零 issue | #1 | pending |
| 5 | Reminder 数据模型 | 创建 `src/core/common/code/models/reminder_model.dart`：Reminder 实体（id/int, group_id/int, title/String, content/String?, scheduled_at/DateTime, status/ReminderStatus, frequency/ReminderFrequency, created_at/DateTime, updated_at/DateTime?）含 fromJson/toJson/fromMap/toMap/copyWith/==/hashCode/toString | `dart analyze lib/src/core/common/code/models/reminder_model.dart` 零 issue | #3, #4 | pending |
| 6 | DateFormatter 时间解析 | 创建 `src/core/common/code/utils/date_formatter.dart`：自然语言时间→DateTime 解析，覆盖 ≥15 条口语表达（今天下午三点、明天上午九点、后天、下周一、下周、半个月后、一个月后、每三天、每周五、每天晚上八点、明天中午、下个月五号、大后天、本周日、半小时后），含边界（闰年、月末、上午12点/下午12点） | `dart analyze lib/src/core/common/code/utils/date_formatter.dart` 零 issue | #2 | pending |
| 7 | StringSanitizer 字符串清洗 | 创建 `src/core/common/code/utils/string_sanitizer.dart`：输入清洗（trim、连续空格合并、控制字符移除、特殊字符过滤、长度截断 max 500、null/空字符串处理） | `dart analyze lib/src/core/common/code/utils/string_sanitizer.dart` 零 issue | #1 | pending |
| 8 | PermissionManager 权限管理 | 创建 `src/core/common/code/permissions/permission_manager.dart`：PermissionManager 抽象类（checkPermission/requestPermission/openSettings）、PermissionStatus 枚举（granted/denied/permanentlyDenied/restricted/unknown）、PermissionType 枚举（microphone/notification/storage）；创建 `permission_manager_stub.dart` Stub 实现（全部返回 granted，供测试用，真实实现在 F-10/F-11） | `dart analyze lib/src/core/common/code/permissions/` 零 issue | #1 | pending |
| 9 | Barrel file 导出 | 创建 `src/core/common/common.dart`：export 所有公开接口（constants + models + utils + permissions），确保无循环依赖 | `dart analyze lib/src/core/common/common.dart` 零 issue | #2, #3, #4, #5, #6, #7, #8 | pending |
| 10 | 单元测试 | test/unit/common/ 下：1) group_model_test.dart（fromJson/toJson 往返、fromMap/toMap、copyWith、==/hashCode、空 icon 处理）；2) reminder_model_test.dart（同上 + status/frequency 枚举序列化）；3) enums_test.dart（枚举值数量、字符串转换、index 正确）；4) date_formatter_test.dart（≥15 条口语时间解析 + 闰年/月末边界）；5) string_sanitizer_test.dart（空/null/超长/特殊字符/控制字符/连续空格）；6) permission_manager_test.dart（Stub 实现行为验证、枚举状态转换）；7) app_constants_test.dart（APP_NAME 非空、DEFAULT_GROUPS 6 组含必要字段） | `flutter test test/unit/common/` 全部通过（≥7 个 test 文件） | #9 | pending |
| 11 | 最终验证 | 1) `flutter analyze` 零 warning；2) `flutter test test/unit/common/` 全部通过；3) `grep -r 'import.*feature' lib/src/core/common/` 返回空（无对上层 import） | 全部通过 | #10 | pending |

---

## 依赖拓扑

```
#1 (F-00 前置)
├── #2 (常量) ──────────────────────┐
├── #3 (枚举) ──────────────┐       │
├── #4 (Group 模型) ────────┤       │
│   └── #5 (Reminder 模型) ←┤───────┤  #5 依赖 #3, #4
├── #6 (DateFormatter) ←依赖 #2 ────┤
├── #7 (StringSanitizer) ───────────┤
└── #8 (PermissionManager) ─────────┘
    └── #9 (Barrel 导出) ← 依赖 #2-#8
        └── #10 (单元测试)
            └── #11 (最终验证)
```

**可并行**：#2, #3, #4, #7, #8 在 #1 完成后可同时推进。#6 依赖 #2。#5 依赖 #3, #4。

---

## 排除项

<!-- 本次明确不做的内容，防止 implementer overreach -->

1. 不实现权限的 Android/iOS 原生方法通道（属于 F-10/F-11 平台适配）
2. 不接入实际 ASR/LLM SDK（SenseVoice-Tiny / Qwen-140M），属于 F-04 语音模块
3. 不实现 Drift 数据库连接和 DAO（属于 F-02 数据库模块）
4. 不实现 Riverpod Provider 注册（属于 F-03 状态管理层）
5. 不实现任何 UI 页面或 Widget（属于 F-05~F-09 feature 模块）
6. 不引入 `intl` 以外的外部依赖（common 层保持最小依赖）
7. 不在 common 层直接依赖 `flutter_riverpod`（Provider 注册在 F-03 单独处理）
