# 功能拆分

---

## 基本信息

- **功能 ID**：F-04
- **功能名称**：路由系统
- **涉及模块**：router

---

## 工作单元

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| 1 | 修复路由编译错误 | 将 app_router.dart 中 AddReminderPage 改为 ReminderFormPage（与 feature/home 实际导出类名一致），确保所有 7 条路由的 builder 引用的 Page 类均存在 | `flutter analyze lib/src/router/` 零 error | 无 | pending |
| 2 | 验证 barrel file 导出 | 确认 router.dart 正确 export code/app_router.dart，外部可通过 `import 'package:home_reminder/src/router/router.dart'` 获取 appRouterProvider | `dart analyze lib/src/router/router.dart` 零 warning，且 `grep 'export' lib/src/router/router.dart` 返回 code/app_router.dart | #1 | pending |
| 3 | 路由表解析单元测试 | 测试 6 条产品路由（/, /add, /voice, /groups, /group/:id, /cleanup）+ /download 均解析到正确 Page 类型；GoRouter.optionFor 对每个路径返回非空 GoRouteMatch | `flutter test test/unit/router/route_resolution_test.dart` 全部通过 | #1 | pending |
| 4 | 路由守卫重定向测试 | 测试 isFirstLaunch+modelNotReady→redirect 到 /download；isFirstLaunch+modelReady→null 放行；已在 /download 时 redirect 返回 null 避免循环 | `flutter test test/unit/router/redirect_guard_test.dart` 全部通过 | #3 | pending |
| 5 | 深层链接与导航栈测试 | 测试 /group/3 路径参数解析 id='3'；go() 清栈到目标、push() 压栈+1、replace() 替换栈顶 | `flutter test test/unit/router/deep_link_test.dart` 全部通过 | #3 | pending |
| 6 | 全门禁验证 | flutter analyze 零 warning + 全部 router 单元测试通过 | `flutter analyze && flutter test test/unit/router/` | #1 #2 #3 #4 #5 | pending |

---

## 依赖拓扑

```
#1 ──→ #2
 │
 └──→ #3 ──→ #4
        │
        └──→ #5
              │
              └──→ #6
```

> #1 是所有工作单元的前置条件（编译通过）。#2 与 #3 可并行。#4 和 #5 均依赖 #3（需要路由解析基础验证通过）。#6 是全量门禁，收集所有产物后执行。

---

## 排除项

1. 不实现自定义 PageTransitionsBuilder — GoRouter 默认 MaterialPage 过渡已满足需求，除非 flutter analyze 后实测发现动画缺失才补充
2. 不修改 feature 层页面代码 — 路由只引用已有页面类，页面内容由各 feature 功能独立实现
3. 不实现 ShellRoute 嵌套导航 — 当前 7 条路由平铺，无底部导航栏需求
4. 不处理 Android 返回键拦截逻辑 — 返回行为由 GoRouter 默认 pop 处理，平台适配是 F-17/F-18 的职责
5. 不引入额外路由库 — 仅使用 go_router，不引入 auto_route、routemaster 等
