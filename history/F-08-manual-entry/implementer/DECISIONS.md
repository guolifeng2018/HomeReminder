# 模块决策记录

<!-- 由 implementer 填写，时间倒序（最新的在最上面）。记录模块内部的重大决策。 -->
<!-- 项目级决策写入 harness/decisions/ -->

---

## 2026-05-30: HomeFab 回调注入模式

- **上下文**：首页需要在 ReminderFormPage 返回后自动刷新数据（invalidate providers）。原 HomeFab 使用 `pushNamed` 无法监听返回结果。
- **选项**：
  - A：HomeFab 接收 `onAdd`/`onVoice` VoidCallback 回调，父组件在回调中 push + await + invalidate；`addRoute`/`voiceRoute` 保留作为 fallback
  - B：HomeFab 内部改为 `Navigator.push` + await + 回调通知父组件（如 `onResult`）
  - C：HomeFab 接收 route 路径，改为 `Navigator.push` + await + provider invalidate 直接在 FAB 内完成
- **决策**：选 **A**（回调注入）。FAB 保持职责单一（展开/收起菜单 + 触发导航），由 HomePage 负责导航执行和数据刷新。`addRoute`/`voiceRoute` 保留确保向后兼容（home_page_test.dart 等现有测试无需修改）。
- **影响**：`home_fab.dart` 新增两个可选 `VoidCallback?` 参数；`home_page.dart` 的 `onTap` 回调从同步改为 async/await + invalidate，`HomeFab` 实例化从 `const` 改为传递回调。

<!-- 模板：复制以下 block 按时间倒序追加

## <日期>: <决策标题>

- **上下文**：为什么需要做这个决策
- **选项**：考虑过哪些方案（A / B / C）
- **决策**：选了什么、为什么
- **影响**：对哪些模块有影响
-->
