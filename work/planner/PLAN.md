# 实现方案

<!-- 由 planner 填写。implementer 据此实现。 -->

---

## 基本信息

- **功能 ID**：F-09
- **功能名称**：模型下载管理

---

## 涉及模块

| 模块 | 变更类型 | 说明 |
|------|---------|------|
| `core/common` | 修改 | 新增 `code/download/` 子模块（模型注册表、下载器、校验器、存储检查、状态管理、编排服务、Provider） |
| `core/common/common.dart` | 修改 | 添加 download 模块 export |
| `feature/model_download` | 修改 | 替换占位符页面为真实下载 UI |
| `pubspec.yaml` | 修改 | 确认 path_provider 依赖已存在；如需要添加 crypto 或 http 依赖 |

---

## 实现步骤

### 步骤 1：模型注册表（#1）

- **内容**：在 `lib/src/core/common/code/download/` 下创建 `model_registry.dart`，定义 `DownloadableModel`（id/name/version/url/sha256/fileSize/targetDir/targetFileName）和 `ModelRegistry`（静态方法返回两个模型元数据）
- **验收标准**：`flutter analyze lib/src/core/common/code/download/model_registry.dart` 零 warning
- **涉及文件**：`lib/src/core/common/code/download/model_registry.dart`

### 步骤 2：断点续传下载器（#2）

- **内容**：`downloader.dart` — `Downloader` 类，使用 `dart:io` HttpClient 发送 HTTP GET + Range 头。核心方法：`startDownload(model, offset)` → 创建 `.part` 文件，追加写入；`pause()` → 关闭连接保留进度；`resume()` → 从 `.part` 字节数 offset 继续；`cancel()` → 删除 `.part`。通过 Stream 推送进度（downloadedBytes, totalBytes）
- **验收标准**：单元测试覆盖：正常下载、断点续传（50% 中断后继续从 50% 开始）、暂停→继续、取消清理 .part、HTTP 错误处理
- **涉及文件**：`lib/src/core/common/code/download/downloader.dart`

### 步骤 3：SHA256 校验器（#3）

- **内容**：`sha256_validator.dart` — `Sha256Validator.validate(filePath, expectedSha256)` 使用 `dart:convert`/`dart:io` 计算文件 SHA256 比对。失败删除文件，重试最多 3 次（每次触发重新下载）。
- **验收标准**：单元测试覆盖：SHA256 匹配→返回 true、不匹配→删除文件返回 false、3 次重试机制
- **涉及文件**：`lib/src/core/common/code/download/sha256_validator.dart`

### 步骤 4：存储空间检查器（#4）

- **内容**：`storage_checker.dart` — `StorageChecker.check(model)` 使用 path_provider 获取可用空间，校验 `availableSpace >= model.fileSize * 1.5 + 50MB`。返回 `StorageCheckResult`（ok / insufficient / error）。
- **验收标准**：单元测试覆盖：空间充足、空间不足、异常处理
- **涉及文件**：`lib/src/core/common/code/download/storage_checker.dart`

### 步骤 5：下载状态管理（#5）

- **内容**：`download_state.dart` — `DownloadState` 枚举（idle/downloading/paused/completed/failed），`DownloadProgress` 类（modelId/state/progress 0-100/downloadedBytes/totalBytes/errorMessage?），`DownloadStateManager` 类管理 Map<modelId, DownloadProgress> 并提供状态变更通知。
- **验收标准**：单元测试覆盖：5 状态全部可达、状态转换正确性、progress 计算准确
- **涉及文件**：`lib/src/core/common/code/download/download_state.dart`

### 步骤 6：下载编排器（#6）

- **内容**：`model_download_service.dart` — `ModelDownloadService` 类协调所有组件。`download(modelId)` 流程：① StorageChecker.check → ② 检查目标文件是否存在且 SHA256 匹配→跳过 ③ Downloader.startDownload ④ Sha256Validator.validate ⑤ DownloadStateManager 更新状态。提供 cancel/pause/resume 代理方法。
- **验收标准**：集成测试覆盖：完整下载流程、SHA256 匹配跳过下载、SHA256 不匹配重新下载、空间不足拒绝、重试 3 次失败标记 failed、暂停/继续/取消
- **涉及文件**：`lib/src/core/common/code/download/model_download_service.dart`

### 步骤 7：Riverpod Provider（#7）

- **内容**：在 `download/` 下创建 `download_providers.dart`。`downloadServiceProvider = Provider((ref) => ModelDownloadService(...))`，`modelDownloadProgressProvider(modelId) = StreamProvider((ref) => ref.read(downloadServiceProvider).progressStream(modelId))`。
- **验收标准**：Provider 单元测试：provider resolve 正常、Stream 推送验证
- **涉及文件**：`lib/src/core/common/code/download/download_providers.dart`

### 步骤 8：模型下载 UI 页（#8）

- **内容**：替换 `lib/src/feature/model_download/code/model_download_page.dart` 占位符。使用 ConsumerWidget + Riverpod 读取下载状态。两个模型卡片（Card + Column）：模型名称/大小/状态图标/LinearProgressIndicator+百分比/已下载MB/总MB。按钮行：暂停/继续（根据状态切换）、重试（failed 时）、取消。存储不足时 AlertDialog。顶部 AppBar 标题「模型下载」。
- **验收标准**：Widget 测试：卡片渲染、进度条更新、按钮状态切换、AlertDialog
- **涉及文件**：`lib/src/feature/model_download/code/model_download_page.dart`

### 步骤 9：barrel 文件导出（#9）

- **内容**：更新 `lib/src/core/common/common.dart` 添加 `export 'code/download/model_registry.dart'` 等。确认 `lib/src/feature/model_download/model_download.dart` 已正确 export UI 文件。
- **验收标准**：`flutter analyze` 零 warning，import 路径正确
- **涉及文件**：`lib/src/core/common/common.dart`、`lib/src/feature/model_download/model_download.dart`

---

## 依赖

| 依赖 | 类型 | 说明 |
|------|------|------|
| `dart:io` | 标准库 | HttpClient（HTTP Range 请求）、File（.part 文件操作）、Digest（SHA256） |
| `dart:convert` | 标准库 | SHA256 字节转十六进制字符串 |
| `path_provider` | 外部库 | 获取应用文档目录 + 可用空间（pubspec.yaml 已存在） |
| `flutter_riverpod` | 外部库 | Provider 状态管理（pubspec.yaml 已存在） |

---

## 排除项

1. 实际模型托管 URL 配置 — 使用占位 URL（`https://models.example.com/sensevoice_tiny_v1.onnx`），后续由运维替换
2. 原生平台下载进度通知（Android Notification + DownloadManager）— 纯 Dart UI 展示
3. 多模型并发下载 — 第一期串行，并发优化放 F-19
4. 模型版本自动检查和增量更新
5. 后台下载（应用切后台后继续下载）— 放 F-19
