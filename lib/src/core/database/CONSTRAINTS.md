# 模块约束 — core/database

<!-- 模块级硬约束。implementer 每个单元完成后自检 -->

---

## 数据约束

1. **禁止** Group name 为空字符串存入数据库（Repository 层抛 ArgumentError）
2. **禁止** Reminder title 为空、groupId ≤ 0、scheduledAt 无效时存入数据库
3. **必须** 所有时间字段以毫秒时间戳（int）存储
4. **必须** status/frequency 以字符串 `name` 存储（非 index）

## 接口约束

1. **禁止** import feature 层任何模块
2. **禁止** 在 Repository 外部直接访问 AppDatabase
3. **必须** 所有 Repository 方法返回 domain 模型（Group/Reminder），非 Drift DataClass
4. **禁止** 使用 `print`、`debugger`、TODO 注释
5. **禁止** 实现数据库迁移（schema_version）
6. **禁止** 实现数据库实例单例/工厂（由 F-03 管理）

## 性能约束

1. **必须** 所有批量操作使用事务包装
2. **必须** 为高频查询列（scheduled_at、group_id、status）建立索引
