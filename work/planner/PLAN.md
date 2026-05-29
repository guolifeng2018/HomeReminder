# 实现方案

---

## 基本信息

- **功能 ID**：F-04
- **功能名称**：路由系统（GoRouter）

---

## 涉及模块

| 模块 | 变更类型 | 说明 |
|------|---------|------|
| src/core/router | **新建** | GoRouter 配置、redirect 守卫、barrel file |
| src/feature/home | 新建文件 | HomePage 占位页 + barrel file |
| src/feature/voice_input | 新建文件 | VoiceInputPage 占位页 + barrel file |
| src/feature/group_manage | 新建文件 | GroupManagePage + GroupDetailPage 占位页 + barrel file |
| src/feature/cleanup | 新建文件 | CleanupPage 占位页 + barrel file |
| src/feature/model_download | **新建** | ModelDownloadPage 占位页 + barrel file |
| lib/main.dart | 修改 | MaterialApp → MaterialApp.router |
| test/unit/router | **新建** | 路由单元测试 |

---

## 实现步骤

### 步骤 1：创建占位页面

- **内容**：在 6 个 feature 模块目录下创建最小占位页面。每个页面为一个 StatelessWidget，仅包含 Scaffold + AppBar + Center(Text('页面名称'))。同时为每个模块创建 barrel file 统一 export。新建 `src/feature/model_download/` 模块用于模型下载占位页。
- **验收标准**：
  ```bash
  flutter analyze lib/ src/feature/   # 零 warning
  find src/feature -name '*.dart' | wc -l   # ≥ 14 个文件（7 页面 + 7 barrel）
  ```
- **涉及文件**：
  - `src/feature/home/code/home_page.dart` + `src/feature/home/home.dart`
  - `src/feature/voice_input/code/voice_input_page.dart` + `src/feature/voice_input/voice_input.dart`
  - `src/feature/group_manage/code/group_manage_page.dart` + `src/feature/group_manage/code/group_detail_page.dart` + `src/feature/group_manage/group_manage.dart`
  - `src/feature/cleanup/code/cleanup_page.dart` + `src/feature/cleanup/cleanup.dart`
  - `src/feature/model_download/code/model_download_page.dart` + `src/feature/model_download/model_download.dart`

### 步骤 2：创建路由模块

- **内容**：创建 `src/core/router/`。实现 `app_router.dart`：
  - 定义 `appRouterProvider`（`Provider<GoRouter>`），依赖 `appConfigProvider`。
  - 定义 `_guardRedirect` 函数：当 `appConfig.isFirstLaunch == true && appConfig.modelDownloadStatus != ModelDownloadStatus.completed` 且当前路径不是 `/download` 时，redirect 到 `/download`；否则返回 `null`（放行）。
  - 7 条路由全量定义，页面通过各自的 barrel file 引用。
  - 创建 `src/core/router/router.dart` barrel file。
- **验收标准**：
  ```bash
  flutter analyze src/core/router/   # 零 warning
  grep -r 'import.*feature' src/core/router/   # 空输出（guard 函数不直接依赖 feature，页面引用在路由表 builder 中）
  ```
- **关键设计决策**：redirect 函数必须接收 `BuildContext` 并通过 `ref.read(appConfigProvider)` 获取配置，因为 go_router 的 `redirect` 回调提供 `context` 和 `state` 两个参数。由于 GoRouter 定义在 Provider 的 `build` 回调中，不能直接使用 `ref.watch`（会循环依赖），需使用 `ref.read` 或通过 `context` 拿到 `ProviderContainer` 后读取。

- **涉及文件**：
  - `src/core/router/code/app_router.dart` — GoRouter 定义 + 守卫函数
  - `src/core/router/router.dart` — barrel file

### 步骤 3：集成到 main.dart

- **内容**：修改 `lib/main.dart`，将 `MaterialApp(... home: ...)` 替换为 `MaterialApp.router(routerConfig: ref.watch(appRouterProvider))`，其中 `ref` 来自 `ConsumerWidget` 或 `ConsumerStatefulWidget`。将 `HomeReminderApp` 从 `StatelessWidget` 改为 `ConsumerWidget` 以获取 `ref`。
- **验收标准**：
  ```bash
  flutter analyze lib/main.dart   # 零 warning
  flutter test test/unit/router/   # 初始路由解析测试通过
  ```
- **涉及文件**：
  - `lib/main.dart` — Widget 类型变更 + routerConfig 注入

### 步骤 4：编写路由单元测试

- **内容**：创建 `test/unit/router/app_router_test.dart`。使用 `ProviderScope.overrides` 注入测试用 GoRouter 实例。覆盖：
  1. 7 条路由 URL 到 Page 的正确映射（`router.go(url)` → `router.location` 断言）
  2. redirect 守卫 4 场景（通过 override appConfigProvider 控制 isFirstLaunch / modelDownloadStatus）
  3. 深层链接路径参数：`router.go('/group/3')` → pathParameters['id'] == '3'
  4. 导航栈：`router.go('/')` → `router.push('/add')` → `router.canPop() == true`
  5. `/download` 本身不被 redirect 守卫拦截（避免无限重定向循环）
- **验收标准**：
  ```bash
  flutter test test/unit/router/   # 全部 PASS，≥ 12 条测试用例
  ```
- **涉及文件**：
  - `test/unit/router/app_router_test.dart`

---

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| go_router ^14.6.2 | 外部库 | 已在 pubspec.yaml 中声明，提供 GoRouter / GoRoute / ShellRoute 等 API |
| flutter_riverpod ^2.6.1 | 外部库 | ProviderScope / Provider / ConsumerWidget |
| src/core/providers | 模块（F-03） | appConfigProvider、AppConfig、ModelDownloadStatus |
| src/core/common | 模块（F-01） | 间接依赖（Group 模型被 GroupDetailPage 引用时可能需要，但占位页不实际使用） |

---

## 排除项

1. **页面 UI 实现**：占位页面仅含 Scaffold + Text 标题，F-07/F-08/F-09/F-10 负责业务 UI。
2. **自定义转场动画**：全部 go_router 默认 Material 转场（`MaterialPage<void>`），不自定义 `CustomTransitionPage`。
3. **模型下载管理器实现**：`/download` 仅占位，F-09 负责下载 UI + 逻辑。
4. **ShellRoute / 嵌套路由**：本次不引入嵌套路由（如底部导航栏 + 子路由），所有路由平铺。
5. **平台深度链接配置**：不做 Android `AndroidManifest.xml` intent-filter / iOS `Info.plist` CFBundleURLTypes 配置，仅验证 GoRouter 路径参数解析。
6. **路由日志 / 分析**：不做路由埋点、导航日志。
7. **自定义错误页**：GoRouter 默认 error page（404 处理），不自定义 `errorBuilder`。
