# 路由系统 — 模块约束

---

## 约束

1. **必须**仅依赖 core 层和 go_router 库，禁止依赖 feature 层（placeholder_pages 是内部 stub，不算 feature 层）
2. **必须**通过 `appRouterProvider` Provider 暴露 GoRouter，main.dart 中通过 `ref.watch(appRouterProvider)` 获取
3. **禁止**在路由 redirect 守卫中执行 I/O 操作或状态修改（仅读取 Provider 状态）
4. **必须**保持 `flutter analyze lib/src/router/` 零 warning
5. **禁止**在路由配置中引入网络请求或数据上传
