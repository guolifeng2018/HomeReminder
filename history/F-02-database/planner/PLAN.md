# 实现方案

<!-- 由 planner 填写。implementer 据此实现。 -->

---

## 基本信息

- **功能 ID**：F-02
- **功能名称**：core/database 数据库模块

---

## 涉及模块

| 模块 | 变更类型 | 说明 |
|------|---------|------|
| core/database | 新建 | Drift 表定义、Repository、barrel file、单元测试 |
| core/common | 仅依赖（只读） | import `Group`、`Reminder`、`ReminderStatus`、`ReminderFrequency`、`DEFAULT_GROUPS` 常量 |

---

## 实现步骤

<!-- 按顺序排列 -->

### 步骤 1：Drift 表定义 + 代码生成（DB-01）

- **内容**：
  1. 创建 `lib/src/core/database/code/database.dart`
  2. 定义 `Groups` 表（@DataClassName('GroupData')）：
     - `id` INTEGER PRIMARY KEY AUTOINCREMENT
     - `name` TEXT NOT NULL
     - `icon` TEXT (nullable)
     - `isPreset` INTEGER DEFAULT 0
     - `sortOrder` INTEGER
     - `createdAt` INTEGER（毫秒时间戳）
     - 索引：`idx_groups_sort_order` ON groups(sort_order)
  3. 定义 `Reminders` 表（@DataClassName('ReminderData')）：
     - `id` INTEGER PRIMARY KEY AUTOINCREMENT
     - `groupId` INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE
     - `title` TEXT NOT NULL
     - `content` TEXT (nullable)
     - `scheduledAt` INTEGER NOT NULL（毫秒时间戳）
     - `status` TEXT DEFAULT 'pending'
     - `frequency` TEXT DEFAULT 'once'
     - `createdAt` INTEGER（毫秒时间戳）
     - `updatedAt` INTEGER (nullable, 毫秒时间戳)
     - 索引：`idx_reminders_scheduled_at` ON reminders(scheduled_at)、`idx_reminders_group_id` ON reminders(group_id)、`idx_reminders_status` ON reminders(status)
  4. 定义 `AppDatabase` 类（`@DriftDatabase(tables: [Groups, Reminders])`）
  5. 运行 `dart run build_runner build --delete-conflicting-outputs`

- **验收标准**：
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  退出码 0，生成 `lib/src/core/database/code/database.g.dart`，无编译错误

- **涉及文件**：
  - `lib/src/core/database/code/database.dart`（新建）

---

### 步骤 2：GroupRepository 实现（DB-02）

- **内容**：
  1. 创建 `lib/src/core/database/code/group_repository.dart`
  2. 构造函数接受 `AppDatabase` 实例
  3. 方法签名：
     ```dart
     Future<Group> insert(Group group)              // name 为空 → throw ArgumentError
     Future<List<Group>> getAll()                    // ORDER BY sort_order ASC
     Future<Group?> getById(int id)
     Future<void> update(Group group)                // 全字段覆盖更新
     Future<void> delete(int id)
     Future<void> initPresetGroups()                 // 事务内 INSERT OR IGNORE 6 个预设分组
     ```
  4. 数据转换逻辑：
     - 写入：`Group → GroupData`（使用 `group.toMap()` 映射字段；注意 Drift 列名使用驼峰 `sortOrder`/`createdAt`/`isPreset`）
     - 读取：`GroupData → Group`（使用 `Group.fromMap(driftRow)`；时间戳字段为 int 毫秒）
  5. 创建测试文件 `test/unit/database/group_repository_test.dart`

- **验收标准**：
  ```bash
  flutter test test/unit/database/group_repository_test.dart
  ```
  全部通过，覆盖：
  - insert 有效 Group → getById 可取出
  - insert name 为空字符串 → throws ArgumentError
  - getAll 返回按 sort_order ASC 排序列表
  - update 修改 name/icon/sortOrder → getById 验证
  - delete 后 getById 返回 null
  - initPresetGroups 调用 2 次 → 总计 6 条记录（幂等）

- **涉及文件**：
  - `lib/src/core/database/code/group_repository.dart`（新建）
  - `test/unit/database/group_repository_test.dart`（新建）

---

### 步骤 3：ReminderRepository 实现（DB-03）

- **内容**：
  1. 创建 `lib/src/core/database/code/reminder_repository.dart`
  2. 构造函数接受 `AppDatabase` 实例
  3. 方法签名：
     ```dart
     Future<Reminder> insert(Reminder reminder)     // title 空/groupId≤0/scheduledAt 无效 → throw
     Future<Reminder?> getById(int id)
     Future<List<Reminder>> getAll()
     Future<List<Reminder>> getByGroupId(int groupId)
     Future<List<Reminder>> getByStatus(ReminderStatus status)
     Future<List<Reminder>> getByDateRange(DateTime start, DateTime end)  // BETWEEN 含边界
     Future<List<Reminder>> getToday()              // 今日 00:00:00 ~ 23:59:59.999
     Future<List<Reminder>> getOverdue()             // scheduledAt < now AND status='pending'
     Future<void> update(Reminder reminder)
     Future<void> delete(int id)
     Future<void> batchUpdateStatus(List<int> ids, ReminderStatus status) // 事务内批量 UPDATE
     Future<T> transaction<T>(Future<T> Function() action)  // 通用事务包装
     ```
  4. 数据转换逻辑：
     - 写入：`Reminder → ReminderData`（status/frequency 存为 `.name` 字符串；时间存毫秒时间戳）
     - 读取：`ReminderData → Reminder`（字符串 status/frequency 通过 `fromMap` 反序列化，兼容 `_parseStatusFromMap`）
  5. 创建测试文件 `test/unit/database/reminder_repository_test.dart`

- **验收标准**：
  ```bash
  flutter test test/unit/database/reminder_repository_test.dart
  ```
  全部通过，覆盖：
  - insert title 为空 → throws ArgumentError
  - insert groupId 无效（≤0）→ throws ArgumentError
  - insert scheduledAt 无效 → throws ArgumentError
  - insert 有效 Reminder → getById 可取出
  - getAll 返回全部
  - getByGroupId 返回指定分组的 reminders
  - getByStatus 按状态正确筛选
  - getByDateRange 含边界值（start/end 恰有数据时返回）
  - getToday 只返回当日 scheduled 的 reminders
  - getOverdue 返回 scheduledAt < now 且 status='pending'
  - update 修改 title/status → getById 验证
  - delete 后 getById 返回 null
  - batchUpdateStatus 传入 3 个 id → 3 条 status 全部更新
  - FK 级联删除：删除 group → 关联 reminders 全部消失

- **涉及文件**：
  - `lib/src/core/database/code/reminder_repository.dart`（新建）
  - `test/unit/database/reminder_repository_test.dart`（新建）

---

### 步骤 4：集成验证 + barrel file（DB-04）

- **内容**：
  1. 创建 `test/unit/database/database_schema_test.dart`，包含：
     - EXPLAIN QUERY PLAN 验证三个索引：
       ```sql
       EXPLAIN QUERY PLAN SELECT * FROM reminders WHERE scheduled_at > ?;
       -- 预期：USING INDEX idx_reminders_scheduled_at
       EXPLAIN QUERY PLAN SELECT * FROM reminders WHERE group_id = ?;
       -- 预期：USING INDEX idx_reminders_group_id
       EXPLAIN QUERY PLAN SELECT * FROM reminders WHERE status = ?;
       -- 预期：USING INDEX idx_reminders_status
       ```
     - 事务回滚测试：批量插入 3 条（第 2 条故意违反约束）→ 3 条全部未入库
  2. 创建 barrel file `lib/src/core/database/database.dart`，export：
     ```dart
     export 'code/database.dart';
     export 'code/group_repository.dart';
     export 'code/reminder_repository.dart';
     ```
  3. 运行 `flutter analyze` 和 grep 检查

- **验收标准**：
  ```bash
  # 索引验证 + 事务回滚测试
  flutter test test/unit/database/database_schema_test.dart --reporter expanded
  
  # 全量测试
  flutter test test/unit/database/
  
  # 静态分析
  flutter analyze lib/src/core/database/
  
  # 依赖方向检查
  grep -r 'import.*feature' lib/src/core/database/ && echo "FAIL: feature import found" || echo "PASS: no feature import"
  ```
  全部通过，`flutter analyze` 零 warning

- **涉及文件**：
  - `test/unit/database/database_schema_test.dart`（新建）
  - `lib/src/core/database/database.dart`（新建）

---

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| drift | 外部库（已安装） | v2.22.0，SQLite ORM |
| sqlite3_flutter_libs | 外部库（已安装） | v0.5.24，SQLite 原生库 |
| drift_dev | 外部库 dev（已安装） | v2.22.0，代码生成器 |
| build_runner | 外部库 dev（已安装） | v2.4.12，构建运行器 |
| core/common | 模块（已完成 F-01） | Group/Reminder 模型、枚举、DEFAULT_GROUPS 常量 |
| flutter_test | SDK（已安装） | 测试框架 |

---

## 排除项

<!-- 明确本次不做，防止 overflow -->

1. **不实现数据库迁移（schema_version 表）**：首版无历史数据，留到需要时再加
2. **不实现独立的 DAO 层**：Drift DAO 与 Repository 合并为一个类文件，每张表一个 Repository
3. **不创建 Riverpod Provider**：数据库实例创建与管理属于 F-03（状态管理 + DI）
4. **不实现数据缓存层**：Repository 直接访问 Drift，无内存缓存
5. **不创建数据库实例单例/工厂**：AppDatabase 构造接受 `QueryExecutor`，实例化由 F-03 管理
6. **不实现 drift_db_viewer 调试工具**：不在本次范围
7. **不修改 pubspec.yaml**：所有 Drift 依赖已在 F-00 脚手架阶段添加
8. **不创建 .moor 或 .drift 独立定义文件**：使用 Dart 注解风格（`@DataClassName`），不使用独立 DSL 文件
