# L2 运行时验证报告

<!-- 由 reviewer 填写。对照 EVALUATOR-RUBRIC.md 四维度评分。 -->

---

## 基本信息

- **功能 ID**：F-09
- **验证日期**：2026-05-30
- **轮次**：round 3

---

## 启动检查

- **结果**：N/A — 无启动入口（纯库模块，无 main()）
- **错误信息**：N/A

---

## 排除项检查

| 排除项 | 是否被实现 | 判定 |
|--------|----------|------|
| 实际模型托管 URL 配置 | 否（使用占位 URL） | ✅ |
| 原生平台下载进度通知 | 否（纯 Dart UI） | ✅ |
| 多模型并发下载 | 否（串行，_activeModelId 互斥） | ✅ |
| 模型版本自动检查和增量更新 | 否 | ✅ |
| 后台下载 | 否 | ✅ |

---

## 测试结果

| 测试类型 | 通过/总数 | 覆盖率 | 失败清单 |
|---------|----------|--------|---------|
| `test/unit/common/` | 188/193 | — | model_registry_test (3), download_provider_test (2) |

### 失败测试明细

| # | 测试 | 实际结果 | 根因 |
|---|------|---------|------|
| 1 | `model_registry_test.dart`: targetPath | `Binding has not yet been initialized` | `getApplicationDocumentsDirectory()` 需要 `TestWidgetsFlutterBinding.ensureInitialized()`，测试未调用 |
| 2 | `model_registry_test.dart`: partPath | 同上 | 同上 |
| 3 | `model_registry_test.dart`: targetDir | 同上 | 同上 |
| 4 | `download_provider_test.dart`: modelDownloadProgressProvider | `Null check operator used on a null value` | `container.read()` 对 StreamProvider 返回 `AsyncLoading`（尚未 emit），`.value!` 为 null |
| 5 | `download_provider_test.dart`: allModelsProgressProvider | `AsyncLoading` is not `Map<String, DownloadProgress>` | 同上 — `AsyncLoading` 不是 `Map` 实例 |

---

## 验收标准对照

| 工作单元 | 验收标准 | 结果 |
|---------|---------|------|
| #1 模型注册表 | 12 tests, 属性/路径/格式化/Registry 查询 | ❌ 3 fail（路径测试 binding 未初始化） |
| #2 下载器 | 6 tests, 事件构造/类型枚举 | ✅ 全部通过 |
| #3 SHA256 校验器 | 8 tests, 匹配/不匹配/重试 | ✅ 全部通过 |
| #4 存储检查器 | 4 tests, 枚举/check 返回值 | ✅ 全部通过 |
| #5 下载状态管理 | 10 tests, 状态枚举/构造/copyWith/Manager | ✅ 全部通过 |
| #6 下载编排器 | 8 tests, idle/初始化/progress/cancel/pause/dispose | ✅ 全部通过 |
| #7 Provider | 4 tests, resolve/list/progress/allModels | ❌ 2 fail（AsyncLoading 未处理） |
| #8 下载 UI | 3 tests, 渲染/AppBar/卡片区域 | ✅ 全部通过 |
| #9 barrel | flutter analyze 零 issue | ✅ |

---

## 四维度评分

<!-- 对照 EVALUATOR-RUBRIC.md -->

| 维度 | 评分 | 说明 |
|------|------|------|
| 正确性 | C | 生产代码的 3 个 FIX-QUEUE 修复全部正确。但 5 个测试失败（均属测试基础设施问题，非生产代码缺陷） |
| 架构合规 | A | 无硬约束违规，依赖方向正确，无调试代码残留，barrel 导出完整 |
| 测试覆盖 | C | 8 个测试文件已创建，188/193 通过。但 5 个测试因 scaffolding 问题失败；缺少 HTTP mock 下载流程测试和 SHA256 重试集成测试 |
| 代码质量 | B | 生产代码结构清晰，命名合理，Downloader 死代码已清除。无重复代码或过长函数 |

---

## 结果

- **判定**：FAIL
- **问题数量**：2 类（共 5 个测试失败）

---

## 问题清单

| # | 测试 | 实际结果 | 根因 | 评分维度 |
|---|------|---------|------|---------|
| 1 | model_registry_test targetPath/partPath/targetDir | `Binding has not yet been initialized` | 测试未调用 `TestWidgetsFlutterBinding.ensureInitialized()` | 测试覆盖 |
| 2 | download_provider_test modelDownloadProgressProvider/allModelsProgressProvider | Null error / AsyncLoading type mismatch | `container.read()` 对 StreamProvider 返回 AsyncLoading | 测试覆盖 |

---

## 建议固化为规则

- **新规则候选**：`path_provider` 在单元测试中使用时，必须调用 `TestWidgetsFlutterBinding.ensureInitialized()` — 可加入 L1 自动化检查
- **新规则候选**：Riverpod StreamProvider 的单元测试中，`container.read()` 不可直接对异步值做同步断言 — 需使用 `container.listen()` 或 `expectLater` + `emits` 模式
