# 项目架构总览

<!-- ARCHITECTURE.md — 由 agent 维护，agent 可更新。描述项目级架构，供所有 agent 参考。 -->

> 本文档描述**项目全局架构**。各模块的详细架构见 `src/<module>/ARCHITECTURE.md`。

---

## 技术栈

| 层次 | 选型 | 版本 |
|------|------|------|
| 语言 | Dart | 3.x（随 Flutter SDK） |
| 框架 | Flutter | 3.22+ |
| 构建工具 | flutter build | — |
| 包管理 | flutter pub | — |
| 状态管理 | Riverpod | flutter_riverpod |
| 数据库 | Drift (SQLite) | latest |
| 测试框架 | flutter_test | Flutter SDK 内置 |
| ASR 推理 | SenseVoice-Tiny + ONNX | INT8 量化，75MB |
| LLM 推理 | Qwen-140M + llama.cpp | 4-bit GGUF，105MB |

---

## 模块列表

### 基础核心层（底层依赖，优先开发）

| 模块 | 职责 | 状态 |
|------|------|------|
| core/common | 全局常量、数据模型、通用工具类、权限管理 | 未开始 |
| core/database | Drift(SQLite) 数据库，分组+提醒 CRUD | 未开始 |

### 业务核心层

| 模块 | 职责 | 状态 |
|------|------|------|
| core/voice | 麦克风录音、离线 ASR、语义结构化解析 | 未开始 |
| core/reminder | 时间解析、定时调度、推迟重试逻辑 | 未开始 |
| core/notification | 系统原生通知推送、到期提醒 | 未开始 |

### 功能页面层（UI 交互）

| 模块 | 职责 | 状态 |
|------|------|------|
| feature/home | 分组概览、今日待办总览 | 未开始 |
| feature/voice_input | 语音录制入口、识别预览、确认创建 | 未开始 |
| feature/group_manage | 预设分组展示、自定义分组CRUD | 未开始 |
| feature/cleanup | 批量标记完成、补货提醒 | 未开始 |

---

## 依赖方向

<!-- 模块间的依赖规则，箭头表示"可依赖" -->

```
feature/home ─────────→ core/database, core/reminder
feature/voice_input ──→ core/voice, core/database, core/reminder
feature/group_manage ─→ core/database
feature/cleanup ──────→ core/database, core/reminder

core/voice ───────────→ core/common
core/reminder ────────→ core/database
core/notification ────→ core/reminder, core/database
core/database ────────→ core/common
core/common ──────────→ 无依赖
```

**规则**：feature 层可依赖 core 层，core 层可依赖同层或下层。依赖方向不可逆，下层禁止 import 上层模块。

---

## 选型理由

| 选型 | 理由 |
|------|------|
| Riverpod | 支持依赖注入、适配分层架构、异步处理友好 |
| Drift | 类型安全 SQLite ORM，编译期 SQL 校验，适合结构化家庭事务数据 |
| flutter_local_notifications | 系统原生通知推送，跨平台稳定 |
| SenseVoice-Tiny | 中文口语识别准确率高，75MB 轻量，支持 ONNX CPU 推理 |
| Qwen-140M + llama.cpp | 140M 参数 4-bit 量化仅 105MB，精准提取时间/内容/分组 |
| 纯本地离线 | 用户隐私保障，无网络依赖 |

---

## 启动命令

```bash
# 安装依赖
flutter pub get

# 代码生成 (Drift)
dart run build_runner build --delete-conflicting-outputs

# 启动开发环境
flutter run

# 运行全部验证
flutter analyze && flutter test
```

---

## 关键决策

<!-- 仅记录跨模块的全局决策，模块内决策见 work/implementer/DECISIONS.md -->
<!-- 详细决策记录见 harness/decisions/ -->

| 日期 | 决策 | 原因 |
|------|------|------|
| 2026-05-29 | 语音+语义模型不入包，首次启动断点续传下载 | 安装包体积控制（180MB 模型不宜打包） |
| 2026-05-29 | 定时提醒强制走系统闹钟/日历 | 规避 Android 厂商杀后台导致漏提醒 |
| 2026-05-29 | 状态管理选 Riverpod | 依赖注入 + 分层架构适配 + 异步友好 |
| 2026-05-29 | 数据库选 Drift | 编译期类型安全、SQL 校验、适合结构化数据 |
