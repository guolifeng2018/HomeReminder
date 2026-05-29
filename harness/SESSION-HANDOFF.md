# 会话交接

<!-- SESSION-HANDOFF.md — agent 在会话结束前写入，新会话开始时读取。 -->
<!-- 来源：L05 上下文连续性、L12 清洁状态 -->

---

## 仓库状态

- **最后 commit**：初始状态
- **构建状态**：尚未构建（Flutter 工程未初始化）
- **测试状态**：无测试

---

## 当前工作

- **功能 ID**：无
- **模块**：无
- **进行中的单元**：无
- **已完成单元**：0

---

## 已知问题

1. 仓库处于初始化阶段，所有 harness 文档和 docs 已补全，但 Flutter 工程尚未创建。
2. 需要先执行 `flutter create` 初始化工程，再开始 F-01 开发。

---

## 下一步

1. 初始化 Flutter 工程（`flutter create`）
2. 配置 pubspec.yaml（添加 drift、flutter_riverpod、flutter_local_notifications 等依赖）
3. 启动 F-01：实现 core:common + core:database

---

## 决策上下文

1. 技术栈：Flutter 3.22+、Dart 3.x、Riverpod、Drift，纯本地离线运行。
2. 功能拆分：5 个功能（F-01 ~ F-05），WIP=1 严格串行。
3. 语音模型：SenseVoice-Tiny (75MB) + Qwen-140M (105MB)，不入包，首次启动后下载。
