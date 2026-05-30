# 模块决策记录

<!-- 由 implementer 填写，时间倒序（最新的在最上面）。记录模块内部的重大决策。 -->
<!-- 项目级决策写入 harness/decisions/ -->

---

## 2026-05-30: 使用占位页面 stub 隔离路由与 feature 层

- **上下文**：app_router.dart 需要引用 7 个 feature 页面（HomePage, AddReminderPage, VoiceInputPage, GroupManagePage, GroupDetailPage, CleanupPage, ModelDownloadPage）。这些 feature 页面分布在 5 个独立的 feature 模块中，部分页面（HomePage, ReminderFormPage）依赖大量 Provider 和数据库，在路由单元测试中难以 mock 全部依赖链。
- **选项**：
  - A：app_router.dart 直接 import 5 个 feature 模块的 barrel file，在测试中 mock 所有 Provider 依赖链
  - B：app_router.dart import 本地的 placeholder_pages.dart，该文件提供 7 个最小 `StatelessWidget` stub（const 构造函数），后续功能完成时替换为真实 import
- **决策**：选 B。理由：1) 路由测试仅需验证路由匹配和 redirect 逻辑，不依赖页面内部实现；2) 避免路由模块对 feature 层产生硬编译依赖，降低模块耦合；3) 符合 planner 方案（PLAN.md 步骤 1 明确要求创建占位页面）
- **影响**：router 模块不再 import 任何 feature 层模块；placeholder_pages.dart 成为 router 模块内部文件；后续 feature 页面全部完成时需再次更新 app_router.dart 的 import

## 2026-05-30: 路由命名：AddReminderPage vs ReminderFormPage

- **上下文**：placeholder_pages.dart 中定义了 `AddReminderPage` 作为 `/add` 路由的占位页面。feature/home 模块中实际的表单页面名为 `ReminderFormPage`（同时支持新建和编辑两种模式）。两个类名不一致。
- **选项**：
  - A：placeholder_pages.dart 中使用 `ReminderFormPage` 与 feature 模块保持一致
  - B：placeholder_pages.dart 中使用 `AddReminderPage`，语义上更准确描述 `/add` 路由的用途（新建提醒）
- **决策**：选 B。理由：1) placeholder_pages.dart 是独立的 stub 文件，不需要与 feature 模块的类名保持一致；2) `AddReminderPage` 更直观地表达 `/add` 路由的职责；3) 后续替换为真实页面时只需修改 import 和 builder 中的类名
- **影响**：仅影响 placeholder_pages.dart 和 app_router.dart 中的类名引用
