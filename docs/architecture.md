# 项目架构

<!-- 本文档由人维护，描述系统的整体设计。agent 可读取作为参考，不修改。 -->

---

## 系统概述

**系统名称**：居净清单 (JuJingList)
**内部代号**：Jujing
**包名**：Android `com.homeclean.jujing` / iOS `com.homeclean.jujing`
**核心目标**：帮助家庭成员管理日常家庭清洁事务，支持语音录入、智能语义解析、分组管理和基于系统闹钟的定时提醒调度。全程纯本地离线运行，保障用户隐私。

---

## 技术选型

| 层次 | 选型 | 理由 |
|------|------|------|
| 语言 | Dart 3.x | Flutter 生态，类型安全，异步友好 |
| 框架 | Flutter 3.22+ | 一套代码 iOS + Android，跨平台开发效率高 |
| 状态管理 | Riverpod | 依赖注入 + 编译期安全 + 分层架构天然适配 |
| 持久化 | Drift (SQLite) | 类型安全 ORM，编译期 SQL 校验，适合结构化事务数据 |
| 测试 | flutter_test | Flutter 官方测试框架，生态完善 |
| ASR 推理 | SenseVoice-Tiny + ONNX | 中文口语识别准确率高，INT8 量化仅 75MB，CPU 推理 |
| LLM 推理 | Qwen-140M + llama.cpp | 140M 参数 GGUF 4-bit 量化仅 105MB，语义提取精准 |
| 系统通知 | flutter_local_notifications | 系统原生通知，跨平台稳定 |
| 音频录制 | record | 轻量音频采集，支持多种编码格式 |

---

## 模块划分

### 分层架构

```
┌─────────────────────────────────────────┐
│         Feature Layer (功能页面)          │
│  home │ voice_input │ group_manage │ cleanup │
├─────────────────────────────────────────┤
│         Core Layer (业务核心)            │
│  voice │ reminder │ notification        │
├─────────────────────────────────────────┤
│         Core Layer (基础核心)            │
│  common │ database                      │
└─────────────────────────────────────────┘
```

### 模块详细设计

#### core/common — 通用模块
- **职责**：全局常量定义、数据模型（Group、Reminder）、通用工具类、扩展方法、权限申请与管理（麦克风、通知、存储权限）
- **对外接口**：`Group` 模型、`Reminder` 模型、权限工具函数、常量枚举
- **约束**：不依赖任何业务模块，仅被其他模块依赖

#### core/database — 数据库模块
- **职责**：Drift (SQLite) 数据库管理，groups 表和 reminders 表的 CRUD 操作
- **对外接口**：`AppDatabase`、`GroupDao`、`ReminderDao`
- **数据表**：
  - `groups`：id, name（分组名称）, created_at（创建时间）, sort_order（排序字段）
  - `reminders`：id, content（提醒内容）, remind_time（提醒时间）, group_id（关联分组）, status（未处理/已清理）, created_at（创建时间）
- **约束**：所有数据库操作必须通过 DAO 层，禁止 Widget 直接访问数据库

#### core/voice — 语音 & 语义解析模块
- **职责**：麦克风录音采集、离线 ASR 语音转文字、基于 Qwen-140M 的语义结构化解析，从文本中提取提醒内容、提醒时间、分组名称
- **对外接口**：`VoiceService.record()`, `VoiceService.transcribe()`, `VoiceService.parseToReminder()`
- **内部结构**：Dart 端音频采集 → Method Channel → 原生 ONNX 推理（ASR）→ 文本 → llama.cpp 推理（LLM）→ 结构化数据
- **约束**：模型文件不打包进 APK/IPA，首次启动后断点续传下载至应用私有目录

#### core/reminder — 提醒调度模块
- **职责**：时间解析（含"下周""半个月后"等口语时间）、基于系统闹钟/日历的定时任务管理、推迟提醒和重试逻辑
- **对外接口**：`ReminderService.schedule()`, `ReminderService.cancel()`, `ReminderService.postpone()`
- **约束**：强制使用系统闹钟/日历 API，禁止纯应用层 Timer 实现定时

#### core/notification — 系统通知模块
- **职责**：调用系统原生通知能力，到期触发本地通知推送
- **对外接口**：`NotificationService.showReminder()`, `NotificationService.cancel()`
- **约束**：通知内容仅使用用户本地数据，禁止包含任何追踪或上报逻辑

#### feature/home — 首页模块
- **职责**：展示全部分组概览卡片、今日待办提醒总览、快速入口
- **依赖**：core/database、core/reminder

#### feature/voice_input — 语音录入页
- **职责**：语音录制按钮、实时识别文本预览、解析结果展示、确认创建提醒
- **依赖**：core/voice、core/database、core/reminder

#### feature/group_manage — 分组管理页
- **职责**：预设分组展示（客厅/卧室/厨房/冰箱/扫地机/地面）、自定义分组增删改、分组导航、查看单分组下全部提醒
- **依赖**：core/database

#### feature/cleanup — 批量清理页
- **职责**：单选/批量选中提醒标记已完成、一键生成补货提醒
- **依赖**：core/database、core/reminder

---

## 数据流

```
用户语音 → 麦克风采集 (record)
    → SenseVoice-Tiny ASR (Method Channel → ONNX 推理)
    → 识别文本
    → Qwen-140M 语义解析 (llama_cpp_dart → 提取内容/时间/分组)
    → 结构化 Reminder 数据
    → Drift 数据库写入
    → ReminderService 注册系统闹钟
    → 到点 → NotificationService 推送系统通知
    → 用户查看/标记完成
```

手动录入路径跳过 ASR/LLM，直接构造 Reminder 数据写入数据库。

---

## 横切关注点

| 关注点 | 策略 | 说明 |
|--------|------|------|
| 日志 | 禁止联网日志，仅本地调试日志，发布前移除 | 保障用户隐私 |
| 错误处理 | 使用 Result 类型统一错误处理，禁止裸 throw | 避免崩溃，优雅降级 |
| 权限管理 | 按需申请（麦克风/通知/存储），权限说明文案仅标注真实用途 | 最小权限原则 |
| 配置管理 | 应用私有目录存储模型文件，禁止硬编码路径 | 跨平台兼容 |
| 隐私 | 全程本地处理，零网络请求，无数据上传/日志上报 | 核心约束 |

---

## 架构约束

1. **依赖方向**：Feature → Core，依赖方向不可逆。Core 层模块禁止 import Feature 层。
2. **跨模块通信**：模块间通过接口（抽象类）通信，禁止直接 import 其他模块的内部实现细节。
3. **数据库访问**：Widget 禁止直接操作数据库，必须通过 Service/Repository 层。
4. **模型不入包**：ASR/LLM 模型不进 APK/IPA，首次启动后断点续传下载。
5. **定时基于系统**：提醒必须基于系统闹钟/日历 API，不用纯应用层 Timer。
6. **平台兼容**：所有平台 API 调用须做版本检查（Android 10+ / iOS 15+）。

---

## 已知技术债

| 问题 | 严重程度 | 计划 |
|------|---------|------|
| 无 | — | — |
