# 模块架构

## 模块概述

- **模块名**：core/router
- **职责**：基于 GoRouter 的应用路由管理，包含路由表定义、redirect 守卫（首次启动 → 模型下载拦截）和导航配置。

---

## 对外接口

| 接口 | 签名 | 说明 |
|------|------|------|
| appRouterProvider | `Provider<GoRouter>` | 全局 GoRouter 实例，供 MaterialApp.router 注入 |

---

## 内部结构

```
code/
  app_router.dart    — GoRouter 定义、redirect 守卫、appRouterProvider
router.dart          — barrel file
```

---

## 依赖

| 依赖模块 | 用途 |
|---------|------|
| core/providers | 读取 appConfigProvider（首次启动标记 + 模型下载状态） |
| feature/home | 首页、添加提醒页面引用 |
| feature/voice_input | 语音录入页面引用 |
| feature/group_manage | 分组管理、分组详情页面引用 |
| feature/cleanup | 清理页面引用 |
| feature/model_download | 模型下载页面引用 |
