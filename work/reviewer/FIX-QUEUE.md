# 修复队列

<!-- 由 reviewer 填写，implementer 读取并逐条修复。 -->
<!-- Round 3：生产代码 FIX-QUEUE 全部修复。新增 5 个测试基础设施问题（2 类），修复工作量约 2 行代码。 -->

---

## 问题 1

- **验证层**：L2
- **评分维度**：测试覆盖
- **位置**：test/unit/common/model_registry_test.dart:3（main 函数首行）
- **实际结果**：`targetPath`、`partPath`、`targetDir` 三个测试抛出 `Binding has not yet been initialized`。
  这三个 getter 内部调用 `getApplicationDocumentsDirectory()`（来自 `path_provider`），该 API 需要通过 `MethodChannel` 与平台通信，必须先在测试中初始化 Flutter binding。
- **根因**：测试文件使用 `void main()` 但未调用 `TestWidgetsFlutterBinding.ensureInitialized()`，导致 `path_provider` 的 `MethodChannel` 无法初始化。
- **期望行为**：三个路径相关测试全部通过。
- **修复指引**：在 `test/unit/common/model_registry_test.dart` 的 `void main() {` 之后、第一个 `group()` 之前添加一行：

  ```dart
  void main() {
    TestWidgetsFlutterBinding.ensureInitialized();  // ← 添加这一行
    group('DownloadableModel', () {
    ...
  ```

  无需修改任何测试逻辑。

---

## 问题 2

- **验证层**：L2
- **评分维度**：测试覆盖
- **位置**：test/unit/common/download_provider_test.dart:40 和 :53
- **实际结果**：
  - `modelDownloadProgressProvider` 测试：`asyncProgress.value!` 抛出 `Null check operator used on a null value`。`container.read()` 对 StreamProvider 返回 `AsyncValue`，初始状态为 `AsyncLoading`，`.value` 为 null。
  - `allModelsProgressProvider` 测试：`expect(asyncProgress, isA<Map<String, DownloadProgress>>())` 失败，因为 `AsyncLoading` 不是 `Map` 实例。
- **根因**：Riverpod `StreamProvider` 的 `container.read()` 同步返回 `AsyncValue`（初始为 `AsyncLoading`），测试未等待第一个数据发射。
- **期望行为**：两个 Provider 测试均通过，正确验证 Provider 返回非空进度数据。
- **修复指引**：将两个测试从同步 `read` 模式改为监听模式。替换 `main()` 中测试 3 和测试 4：

  ```dart
  test('modelDownloadProgressProvider 返回非空进度', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(downloadServiceProvider);

    // 等待 StreamProvider 首次发射
    final progress = await container
        .read(modelDownloadProgressProvider('sensevoice-tiny-v1').future)
        .first;
    expect(progress, isNotNull);
    expect(progress.modelId, 'sensevoice-tiny-v1');
    expect(progress.state, DownloadState.idle);
  });

  test('allModelsProgressProvider 返回非空 Map', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(downloadServiceProvider);

    // 等待 StreamProvider 首次发射
    final allProgress = await container
        .read(allModelsProgressProvider.future)
        .first;
    expect(allProgress, isNotNull);
    expect(allProgress, isA<Map<String, DownloadProgress>>());
    expect(allProgress.length, 2);
  });
  ```

  核心变化：(a) `test()` 回调改为 `async`；(b) 使用 `.future.first` 等待 StreamProvider 首次数据发射，替代同步 `.read()` + `.value!`。
