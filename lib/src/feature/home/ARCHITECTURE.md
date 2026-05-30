# 模块架构

<!-- 由 implementer 填写。描述本模块的架构设计。 -->

---

## 模块概述

- **模块名**：feature/home
- **职责**：首页 UI — 分组概览卡片、今日待办时间线、状态筛选、空状态、FAB 展开菜单、响应式布局

---

## 对外接口

| 接口 | 签名 | 说明 |
|------|------|------|
| HomePage | `ConsumerStatefulWidget` | 首页入口，组装全部子组件，provider 驱动数据 |
| homeProviders | `groupsProvider`, `todayRemindersProvider`, `filterProvider`, `filteredRemindersProvider` | 首页数据 Provider 集合 |

---

## 内部结构

```
code/
├── home_providers.dart        # HOME-01: Riverpod Provider 层
├── home_header.dart           # HOME-02: 页面头部组件
├── group_overview_card.dart   # HOME-03: 分组概览卡片
├── group_overview_bar.dart    # HOME-04: 分组卡片横向列表
├── today_timeline.dart        # HOME-05: 今日待办时间线列表
├── status_filter_bar.dart     # HOME-06: 状态筛选 TabBar
├── empty_home_view.dart       # HOME-07: 空状态组件
├── home_fab.dart              # HOME-08: FAB 展开菜单
├── home_page.dart             # HOME-09: 首页组装 + 响应式布局
home.dart                      # HOME-10: barrel file
```

---

## 依赖

| 依赖模块 | 用途 |
|---------|------|
| core/common | Group、Reminder 模型，ReminderStatus 枚举 |
| core/database | GroupRepository、ReminderRepository（通过 provider） |
| core/providers | groupRepositoryProvider、reminderRepositoryProvider |
| router | GoRouter 路由注册 |
