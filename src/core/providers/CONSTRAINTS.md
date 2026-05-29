# 模块约束

<!-- 由 implementer 填写。本模块的硬约束，用"必须/禁止"语言。 -->
<!-- implementer 每完成一个单元后自检这些规则。reviewer L1 对照检查。 -->

---

## 数据约束

1. **必须**使用 `NativeDatabase.memory()` 作为数据库实例（F-03 阶段），后续模块可按需 override
2. **禁止**在 Provider 中硬编码数据库文件路径

---

## 接口约束

1. **禁止** import feature 层任何模块
2. **必须**所有 Service Provider 默认注入 stub 实现，声明为可 override
3. **禁止** Provider 之间形成循环依赖（A depends on B depends on A）
4. **必须** appConfigProvider 默认值 isFirstLaunch=true, modelDownloadStatus=idle

---

## 性能约束

1. **必须** databaseProvider 在 dispose 时调用 `db.close()` 释放资源
2. **禁止** Repository Provider 中执行耗时操作（如批量数据处理）的同步初始化
