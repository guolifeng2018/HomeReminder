# 功能拆分

<!-- 由 planner 填写。implementer 据此分配工作单元。 -->

---

## 基本信息

- **功能 ID**：F-02
- **功能名称**：core/database 数据库模块
- **涉及模块**：core/database（新建），依赖 core/common（F-01 已完成）

---

## 工作单元

<!-- 每个单元 = 单一行为 + 可执行验证命令 + 依赖关系 -->

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| DB-01 | Drift 表定义 + 代码生成 | 在 `lib/src/core/database/code/database.dart` 中定义 `groups` 表（含索引 idx_group_sort_order）、`reminders` 表（含 FK ON DELETE CASCADE、三个索引）、`AppDatabase` 类，配置 `@DriftDatabase` 注解，运行 build_runner 生成 `.g.dart` | `dart run build_runner build --delete-conflicting-outputs` 退出码 0，`lib/src/core/database/code/database.g.dart` 文件存在 | F-01（仅 import common 模型） | pending |
| DB-02 | GroupRepository 实现 | 创建 `lib/src/core/database/code/group_repository.dart`，实现 `insert`(空 name 抛 ArgumentError)、`getAll`(ORDER BY sort_order ASC)、`getById`、`update`、`delete`、`initPresetGroups`(INSERT OR IGNORE 事务) 六个方法 | `flutter test test/unit/database/group_repository_test.dart` 全部通过（覆盖：insert 正常→getById 返回；insert 空 name→throws；getAll 按 sort_order 排序；update→getById 验证；delete→getById 返回 null；initPresetGroups 幂等调用 2 次→仅 6 条记录） | DB-01 | pending |
| DB-03 | ReminderRepository 实现 | 创建 `lib/src/core/database/code/reminder_repository.dart`，实现 `insert`(title/groupId/scheduledAt 必填校验)、`getById`、`getAll`、`getByGroupId`、`getByStatus`、`getByDateRange`(scheduled_at BETWEEN，含边界值)、`getToday`/`getOverdue` 便捷方法、`update`、`delete`、`batchUpdateStatus`(事务内批量 UPDATE)、`transaction` 通用事务包装 | `flutter test test/unit/database/reminder_repository_test.dart` 全部通过（覆盖：insert 必填字段校验 title 空/groupId 0/scheduledAt 无效均抛异常；CRUD 主路径；getByGroupId 返回正确子集；getByStatus 按状态筛选；getByDateRange 含边界值；getToday 当日范围正确；getOverdue 仅返回过期+status=pending；batchUpdateStatus 批量修改；FK 级联删除 group→关联 reminders 消失） | DB-01, DB-02（需要 groups 表有数据以测 FK） | pending |
| DB-04 | 索引验证 + 事务回滚测试 + barrel file + 最终验收 | 编写索引 EXPLAIN QUERY PLAN 验证测试、事务回滚边界测试；创建 barrel file `lib/src/core/database/database.dart`；最终 `flutter analyze` 零 warning；grep 验证无 feature 层 import | `flutter test test/unit/database/` 全部通过（含 EXPLAIN QUERY PLAN 三个索引命中断言 + 事务回滚批量插入中途失败不部分提交）；`flutter analyze lib/src/core/database/` 零 warning；`grep -r 'import.*feature' lib/src/core/database/` 返回空 | DB-02, DB-03 | pending |

---

## 依赖拓扑

```
DB-01 (表定义 + 代码生成)
  ├──→ DB-02 (GroupRepository + 测试)
  │       └──→ DB-04 (索引/回滚测试 + barrel + 验收)
  └──→ DB-03 (ReminderRepository + 测试)
          └──→ DB-04 (索引/回滚测试 + barrel + 验收)
```

DB-02 和 DB-03 可并行开发（在 DB-01 完成后）。DB-04 是最终集成验证，必须串行在 DB-02 和 DB-03 之后。

---

## 排除项

<!-- 本次明确不做的内容，防止 implementer overreach -->

1. **不实现数据库迁移（schema_version）**：首版无历史数据，不需要迁移逻辑
2. **不实现 DAO（Data Access Object）独立层**：Drift 的 DAO 注解与 Repository 合并为单一类，避免过度分层
3. **不实现 Riverpod Provider 封装**：数据库实例的 Provider 注册属于 F-03（状态管理 + DI），本次仅在 Repository 类中暴露方法
4. **不实现数据库实例单例**：AppDatabase 构造接受 `QueryExecutor`，实例管理留给 F-03
5. **不引入 `drift_db_viewer` 或调试面板**：调试工具不在本次范围
