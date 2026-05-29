# 模块约束

## 路由约束

1. **必须**使用 go_router 默认 Material 转场动画，禁止自定义 PageTransitionsBuilder
2. **允许**引入 core 层和 feature 层模块（路由模块位于应用组合根，不受分层依赖限制）
3. **必须**保证 `/download` 不被 redirect 守卫拦截（避免无限重定向循环）

## 守卫约束

1. **必须**通过 `ProviderScope.containerOf(context)` 获取 ProviderContainer，禁止缓存或跨请求复用
2. **禁止**在 redirect 回调中执行副作用操作（网络请求、数据库写入等）
3. redirect 返回值**必须**为 `null`（放行）或 `String`（重定向目标路径）

## 组件约束

1. **必须**使用 MaterialPage（GoRouter 默认），禁止逐路由自定义 pageBuilder
