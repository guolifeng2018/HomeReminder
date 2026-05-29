# 功能拆分

---

## 基本信息

- **功能 ID**：F-04
- **功能名称**：路由系统（GoRouter）
- **涉及模块**：core/router（新建）、feature/*（placeholder pages）、main.dart（修改）

---

## 工作单元

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| 1 | 占位页面 | 在 feature 各模块创建最小占位页面（HomePage / AddReminderPage / VoiceInputPage / GroupManagePage / GroupDetailPage / CleanupPage / ModelDownloadPage），每个页面仅含 Scaffold + Text 标题，确保编译通过 | `flutter analyze lib/ src/feature/` 零 warning，7 个占位页面均存在且可 import | 无 | pending |
| 2 | 路由模块 | 创建 `src/core/router/` 模块：GoRouter 定义 7 条路由（`/` `/add` `/voice` `/groups` `/group/:id` `/cleanup` `/download`），redirect 守卫函数（读取 appConfigProvider 判断 isFirstLaunch + modelDownloadStatus），barrel file `router.dart` | `flutter analyze src/core/router/` 零 warning，`grep -r 'import.*feature' src/core/router/` 返回空（路由模块不 import feature，页面引用通过 import 各自模块的 barrel file 但 guard 函数不依赖 feature 层），GoRouter 实例化不抛异常 | #1 | pending |
| 3 | main.dart 集成 | 将 `main.dart` 中的 `MaterialApp` 替换为 `MaterialApp.router`，注入 `routerConfig`，移除废弃的 `home` / `routes` 属性 | `flutter analyze lib/main.dart` 零 warning，应用启动后默认路由 `/` 渲染 HomePage 占位页 | #2 | pending |
| 4 | 路由单元测试 | 编写 `test/unit/router/` 测试文件：覆盖 7 条路由 URL→Page 正确映射、redirect 守卫四种场景（首次+未就绪→拦截、首次+已就绪→放行、非首次+未就绪→放行、非首次+已就绪→放行）、深层链接 `/group/3` 路径参数解析、go/push 导航栈深度 | `flutter test test/unit/router/` 全部通过，覆盖率 ≥ 路由守卫全分支 + 全部路由匹配 | #3 | pending |

---

## 依赖拓扑

```
#1（占位页面）──→ #2（路由模块）──→ #3（main.dart 集成）──→ #4（路由测试）
```

全部串行：占位页面必须先存在（编译依赖），路由模块需要页面引用，main.dart 依赖 router 实例化，测试依赖完整可运行的应用。

---

## 排除项

1. **页面 UI 实现**：占位页面仅包含 Scaffold + Text 标题，不做任何业务 UI。F-07/F-08/F-09/F-10 留给对应 feature 工单实现。
2. **自定义转场动画**：全部使用 go_router 默认 Material 转场，不自定义 PageTransitionsBuilder。
3. **模型下载管理器实现**：`/download` 路由对应 ModelDownloadPage 占位页（仅空壳），F-09 负责其下载 UI 实现。
4. **认证/权限守卫**：本次守卫仅处理首次启动→模型下载的重定向，不做登录/权限等业务守卫。
5. **深层链接平台配置**：不做 Android intent-filter / iOS universal link 的平台级配置，仅保证 GoRouter 路径参数解析正确。
