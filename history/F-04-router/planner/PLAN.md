# 实现方案

---

## 基本信息

- **功能 ID**：F-04
- **功能名称**：路由系统

---

## 涉及模块

| 模块 | 变更类型 | 说明 |
|------|---------|------|
| lib/src/router/code/app_router.dart | 修改 | 修复 AddReminderPage → ReminderFormPage 类名引用 |
| lib/src/router/router.dart | 验证 | 确认 barrel file 导出正确 |
| test/unit/router/ | 新建 | 创建 router 单元测试目录及 3 个测试文件 |

---

## 实现步骤

### 步骤 1：修复编译错误

- **内容**：app_router.dart 第 54 行引用了不存在的 `AddReminderPage`，实际类名是 `ReminderFormPage`（来自 feature/home/code/reminder_form_page.dart）。将 import 和 builder 中的类名修正，确保 flutter analyze 零 error。
- **验收标准**：`flutter analyze lib/src/router/` 输出 "No issues found!"
- **涉及文件**：`lib/src/router/code/app_router.dart`

### 步骤 2：编写路由解析单元测试

- **内容**：创建 `test/unit/router/route_resolution_test.dart`，使用 `MaterialApp.router` + `ProviderScope` 包裹测试 Widget，通过 `GoRouter.of(context)` 分别对 '/'、'/add'、'/voice'、'/groups'、'/group/3'、'/cleanup'、'/download' 执行 `go()` 导航，断言当前 location 匹配预期路径。覆盖边界：空路径参数 `/group/` 应默认 id=''。
- **验收标准**：`flutter test test/unit/router/route_resolution_test.dart` 全部 7 条路由通过
- **涉及文件**：`test/unit/router/route_resolution_test.dart`（新建）

### 步骤 3：编写路由守卫重定向测试

- **内容**：创建 `test/unit/router/redirect_guard_test.dart`。通过 ProviderScope.overrides 注入不同 `appConfigProvider` 状态组合：(a) isFirstLaunch=true + modelNotReady → 导航到 '/' 时应 redirect 到 '/download'；(b) isFirstLaunch=true + modelCompleted → 放行到 '/'；(c) isFirstLaunch=false + any → 放行；(d) 已在 '/download' 时任何状态 → 不循环 redirect。使用 `GoRouter.optionFor()` 或 `go()` 后断言 `router.routerDelegate.currentConfiguration.uri.toString()`。
- **验收标准**：`flutter test test/unit/router/redirect_guard_test.dart` 4 种组合全部通过
- **涉及文件**：`test/unit/router/redirect_guard_test.dart`（新建）

### 步骤 4：编写深层链接与导航栈测试

- **内容**：创建 `test/unit/router/deep_link_test.dart`。(a) 测试 `/group/3` 路径参数：`state.pathParameters['id']` 返回 '3'；(b) 测试 `context.go('/add')` 后导航栈为 ['/add']（清栈）；(c) 测试 `context.push('/add')` 后栈深度 +1；(d) 测试 `/add` 页内 `context.replace('/voice')` 栈深度不变但顶部路径为 '/voice'。使用 `GoRouterState.of(context)` 取 pathParameters。
- **验收标准**：`flutter test test/unit/router/deep_link_test.dart` 全部 4 个场景通过
- **涉及文件**：`test/unit/router/deep_link_test.dart`（新建）

### 步骤 5：全门禁验证

- **内容**：运行 `flutter analyze` 确认全项目零 warning，运行 `flutter test test/unit/router/` 确认 3 个测试文件全部通过。
- **验收标准**：`flutter analyze` 输出 "No issues found!" 且 `flutter test test/unit/router/` exit code=0
- **涉及文件**：全部 router 模块文件 + 测试文件

---

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| go_router | 外部库 | 已在 pubspec.yaml 中声明，F-00 已安装 |
| flutter_riverpod | 外部库 | 已在 pubspec.yaml 中声明，F-03 已完成 Provider 定义 |
| core/providers (F-03) | 模块 | appConfigProvider 提供 isFirstLaunch + modelDownloadStatus 状态 |
| feature/home, feature/voice_input, feature/group_manage, feature/cleanup, feature/model_download | 模块 | 各模块提供 Page Widget 供路由 builder 引用 |

---

## 排除项

1. 不实现自定义 PageTransitionsBuilder — GoRouter 默认 MaterialPage 过渡已满足需求
2. 不修改 feature 层页面代码 — 路由只引用已有页面类
3. 不实现 ShellRoute 嵌套导航 — 7 条路由平铺
4. 不处理平台返回键逻辑 — 由 GoRouter 默认 pop 处理
5. 不引入额外路由库
6. 不编写集成测试（integration_test）— 路由集成测试在 F-07 等页面功能实现后补充
