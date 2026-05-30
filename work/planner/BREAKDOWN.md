# 功能拆分

<!-- 由 planner 填写。implementer 据此分配工作单元。 -->

---

## 基本信息

- **功能 ID**：F-09
- **功能名称**：模型下载管理
- **涉及模块**：`core/common`（基础设施）、`feature/model_download`（UI）

---

## 工作单元

| # | 单元名称 | 描述 | 验证命令 | 依赖 | 状态 |
|---|---------|------|---------|------|------|
| 1 | 模型注册表 | 定义 DownloadableModel 数据类（id/name/version/url/sha256/fileSize/targetDir/targetFileName），ModelRegistry 包含两个模型元数据（SenseVoice-Tiny ONNX 75MB + Qwen-140M GGUF 105MB） | `dart run test/unit/common/model_registry_test.dart` | 无 | pending |
| 2 | 断点续传下载器 | Downloader 类：HTTP GET + Range header 从已下载字节 offset 开始，追加写入 .part 文件，完成后 rename 到目标文件。支持取消/暂停 | `dart run test/unit/common/downloader_test.dart` | #1 | pending |
| 3 | SHA256 校验器 | Sha256Validator：计算文件 SHA256，比对注册表预期值。失败删除文件，最多重试 3 次 | `dart run test/unit/common/sha256_validator_test.dart` | #1 | pending |
| 4 | 存储空间检查器 | StorageChecker：获取设备可用空间（path_provider），校验剩余空间 ≥ 模型大小 × 1.5 + 50MB 余量 | `dart run test/unit/common/storage_checker_test.dart` | #1 | pending |
| 5 | 下载状态管理 | DownloadState 枚举（idle/downloading/paused/completed/failed），DownloadProgress（modelId + state + progress 0-100 + downloadedBytes + totalBytes）。DownloadStateManager 管理每模型独立状态 | `dart run test/unit/common/download_state_test.dart` | #1 | pending |
| 6 | 下载编排器 | ModelDownloadService：协调 #1~#5，提供 download(modelId) 方法。前置检查：存储空间→模型文件已存在且 SHA256 匹配则跳过→否则开始下载→下载完 SHA256 校验→标记 completed。提供 cancel(modelId)、pause(modelId)、resume(modelId) | `dart run test/unit/common/model_download_service_test.dart` | #2 #3 #4 #5 | pending |
| 7 | Riverpod Provider | DownloadServiceProvider（注入 ModelDownloadService），modelDownloadProgressProvider(modelId) 按模型 ID 返回 DownloadProgress Stream | `flutter test test/unit/common/download_provider_test.dart` | #6 | pending |
| 8 | 模型下载 UI 页 | 替换 feature/model_download 占位符。两个模型卡片（名称+大小+状态图标+进度条+已下载/总大小+暂停/继续/重试按钮+ETA），存储不足 AlertDialog | `flutter test test/unit/common/download_ui_test.dart` | #7 | pending |
| 9 | barrel 文件 + 导出 | core/common/common.dart 导出 download 模块，feature/model_download/model_download.dart 更新 export | `flutter analyze lib/src/core/common/ lib/src/feature/model_download/` | #7 #8 | pending |

---

## 依赖拓扑

```
#1 ──→ #2 ──→ #6 ──→ #7 ──→ #8 ──→ #9
#1 ──→ #3 ──→ #6
#1 ──→ #4 ──→ #6
#1 ──→ #5 ──→ #6
```

#2/#3/#4/#5 可并行开发，都仅依赖 #1。#6 需要等待 #2~#5 全部完成。#7~#9 串行。

---

## 排除项

1. 实际模型文件托管 URL（SenseVoice-Tiny / Qwen-140M）— 使用占位 URL，后续由运维配置
2. 原生平台下载通知（Android DownloadManager）— 纯 Dart 层实现
3. 多模型并发下载 — 第一期串行下载，并发放到 F-19 性能优化
4. 下载速度限制 / 带宽管理
5. 模型版本自动更新检查
