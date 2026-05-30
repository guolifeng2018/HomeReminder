# 模块约束

<!-- 由 implementer 填写。本模块的硬约束，用"必须/禁止"语言。 -->
<!-- implementer 每完成一个单元后自检这些规则。reviewer L1 对照检查。 -->

---

## 数据约束

1. **禁止**在 Widget 中直接访问 Drift 数据库，必须通过 Repository/Provider 层。
2. **必须**使用 Riverpod Provider（groupsProvider、todayRemindersProvider、filterProvider、filteredRemindersProvider）管理所有数据状态。

## 接口约束

1. **必须**所有 Widget 支持无数据空状态渲染（数据为空时不 crash）。
2. **禁止**将首页业务逻辑（数据查询、过滤）写在 Widget build 方法中，必须在 Provider 层完成。

## 性能约束

1. **必须**分组卡片列表使用 `ListView.builder` 懒加载，禁止一次性渲染全部。
2. **必须**今日待办列表使用 `ListView.builder` 懒加载，禁止一次性渲染全部。
