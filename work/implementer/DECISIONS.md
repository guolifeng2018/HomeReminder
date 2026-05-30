# 模块决策记录

<!-- 由 implementer 填写，时间倒序（最新的在最上面）。记录模块内部的重大决策。 -->
<!-- 项目级决策写入 harness/decisions/ -->

---

## 2026-05-30: F-09 下载模块放在 core/common 而非独立模块

- **上下文**：F-09 模型下载管理，feature_list.json 中 `module` 字段为 `"core/common"`，且仅依赖 F-01（core/common）
- **选项**：A) 新建独立 `core/download` 模块 / B) 放在 `core/common/code/download/` / C) 放在 `feature/model_download/` 内
- **决策**：选 B，放在 `core/common/code/download/` 子目录。理由：下载基础设施（HTTP、SHA256、存储检查）是通用工具类，符合 common 模块定位"全局常量、数据模型、通用工具类"；仅依赖 common 无上层依赖；UI 页面仍放在 feature/model_download 保持关注点分离。
- **影响**：common.dart barrel 新增 8 行 export；下游模块可通过统一的 common.dart 导入全部下载组件。

## 2026-05-30: 使用 dart:io HttpClient 而非 http 包

- **上下文**：需要 HTTP Range 请求实现断点续传下载
- **选项**：A) `package:http` / B) `package:dio` / C) `dart:io` HttpClient
- **决策**：选 C。dart:io HttpClient 原生支持 Range header、Stream 响应、连接超时控制，无需额外依赖。项目已有 path_provider 用于路径管理，无需引入新的网络库。
- **影响**：pubspec.yaml 无新增依赖；StorageChecker 使用 `dart:io` Process.run 调用系统 `df` 命令获取磁盘空间。

## 2026-05-30: 串行下载策略

- **上下文**：两个模型（75MB + 105MB）需要下载，PLAN.md 排除项中明确"第一期串行下载"
- **选项**：A) 并行下载 / B) 串行下载
- **决策**：选 B。ModelDownloadService 通过 `_activeModelId` 互斥锁保证同时只有一个下载任务；并发优化延后到 F-19。
- **影响**：download() 方法拒绝在另一个下载进行中时启动新下载；UI 中的按钮行为基于单个模型的 `_activeModelId` 判断。

## 2026-05-30: 存储检查双重策略

- **上下文**：跨平台获取磁盘可用空间没有统一的 Dart API
- **选项**：A) 仅用 path_provider / B) Process.run df + fallback
- **决策**：选 B。优先调用系统 `df -k` 命令解析精确可用空间（macOS/Linux 适用），失败或 Windows 平台时 fallback 到目录写入测试。真实准确性依赖平台，当前为保守策略（可写入即通过）。
- **影响**：StorageChecker 有两个代码路径，`_parseAvailableSpace` 解析 df 输出，`_fallbackCheck` 做简单磁盘写入测试。
