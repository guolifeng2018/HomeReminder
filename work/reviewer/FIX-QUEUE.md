# FIX-QUEUE — F-04 路由系统

## 问题 1

- **验证层**：L1
- **评分维度**：架构合规
- **位置**：`lib/src/core/router/code/app_router.dart:11-15`
- **实际结果**：`core/router` 模块直接 import 了 5 个 `feature/*` 模块的 barrel file（home、voice_input、group_manage、cleanup、model_download），用于在路由表的 `builder` 回调中实例化占位页面 Widget
- **根因**：GoRouter 路由表需要引用 feature 层页面 Widget 才能路由到对应页面，但 `core` 层处于架构下层，依赖 `feature` 层（上层）违反了分层依赖规则（CONSTRAINTS.md §1："必须遵守分层依赖规则：feature → core，依赖方向不可逆。下层禁止 import 上层模块"）
- **期望行为**：`core/router` 模块不应直接 import feature 层。路由配置需重新设计以符合分层约束
- **修复指引**：

  方案一（**推荐**）：将路由模块从 `lib/src/core/router/` 移至 `lib/src/router/`（应用组合根层级）。理由是：路由天然属于"应用胶水层"——它需要同时了解 core 和 feature，所以不应放在 core 也不应放在 feature，而应放在架构的"组合根"位置。变更步骤：
  1. `mv lib/src/core/router/ lib/src/router/`
  2. 更新 `lib/main.dart` 中 `import 'src/core/router/router.dart'` → `import 'src/router/router.dart'`
  3. 更新 `test/unit/router/app_router_test.dart` 中 import 路径
  4. 更新 `lib/src/core/router/PROGRESS.md` → `lib/src/router/PROGRESS.md`
  5. 更新 `harness/ARCHITECTURE.md` 模块列表中 `core/router` 的描述（从"基础核心层"移至独立的"应用胶水层"）

  方案二（备选）：使用路由注册模式。在 feature 各模块中通过 Registry 注册路由，core/router 仅定义路由框架接口和 redirect 守卫，不直接引用 feature Widget。但此方案改动更大，且当前占位页面阶段过度设计。
