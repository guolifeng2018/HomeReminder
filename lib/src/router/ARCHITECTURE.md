# 模块架构

## 模块概述

- **模块名**：router（应用胶水层/组合根）
- **职责**：基于 GoRouter 的应用路由管理，包含路由表定义、redirect 守卫（首次启动 → 模型下载拦截）和导航配置。路由模块位于应用组合根层级，可同时引用 core 和 feature 层。

---

## 对外接口

| 接口 | 签名 | 说明 |
|------|------|------|
| appRouterProvider | `Provider<GoRouter>` | 全局 GoRouter 实例，供 MaterialApp.router 注入 |

---

## 内部结构

```
code/
  app_router.dart         — GoRouter 定义、redirect 守卫、appRouterProvider
  placeholder_pages.dart  — 7 个最小 StatelessWidget stub，供路由配置编译使用
router.dart               — barrel file，导出 app_router.dart
```

---

## 依赖

| 依赖模块 | 用途 |
|---------|------|
| core/providers | 读取 appConfigProvider（首次启动标记 + 模型下载状态） |
| 无 feature 层依赖 | 当前使用占位页面 stub，后续功能完成时替换为真实页面 import |

> **分层说明**：router 属于应用胶水层（组合根），不处于 core 层或 feature 层。它可以合法引用 core 层和 feature 层，不违反 CONSTRAINTS.md §1 分层依赖规则。该约束仅禁止 core 层逆依赖 feature 层，组合根不受此限制。
