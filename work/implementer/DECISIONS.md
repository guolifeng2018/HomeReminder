# 路由系统 — 实现决策

<!-- implementer 在开发过程中作出的重要决策，时间倒序 -->

---

## 2026-05-30: 占位页面策略

- **决策**：在 `lib/src/router/code/placeholder_pages.dart` 中为 7 个目标页面创建最小 StatelessWidget stub，解决路由配置对尚未实现的 feature 页面的编译依赖
- **原因**：F-04 路由系统是框架层，不应依赖尚未开发的 feature 页面。占位页面让路由配置可独立编译和测试，后续 feature 开发时直接替换 import 即可
- **替代方案**：使用 `Builder` 回调动态创建页面 — 但会增加路由配置复杂度，不利于类型安全
- **后续影响**：F-07/F-09/F-13/F-14/F-15 开发时需将对应页面的 import 从 placeholder_pages.dart 改回真实 feature 模块

## 2026-05-30: GoRouter 平铺路由

- **决策**：7 条路由平铺在 GoRouter 根级，不使用 ShellRoute 嵌套
- **原因**：当前页面间无共享导航壳（如 BottomNavigationBar），平铺路由更简洁。后续如需要 Tab 导航，可重构为 ShellRoute
- **替代方案**：ShellRoute + StatefulShellRoute — 过度设计，当前不需要

## 2026-05-30: 删除 history/F-04-router/ 遗留

- **决策**：删除 `history/F-04-router/` 目录，该目录包含旧版本路由尝试的半成品
- **原因**：旧文件引用了不存在的模块路径，与新方案不一致，会误导后续开发者
