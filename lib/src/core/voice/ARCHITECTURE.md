# 模块架构

<!-- 由 implementer 填写。描述本模块的架构设计。 -->

---

## 模块概述

- **模块名**：core/voice
- **职责**：麦克风录音与音频采集管理，封装权限请求、录音生命周期、状态机、保护机制及 Method Channel 桥接

---

## 对外接口

| 接口 | 签名 | 说明 |
|------|------|------|
| AudioRecorderState | `enum { idle, recording, paused, stopped, error }` | 录音状态五态枚举 |
| AudioRecorderStateNotifier | `class` 含 `Stream<AudioRecorderState> stateStream` | 状态机，广播状态变更 |
| MicPermissionHandler | `Future<MicPermissionResult> requestMicrophonePermission()` | 麦克风权限处理器 |
| MicPermissionResult | `enum { granted, denied, needsSettings }` | 权限结果三态枚举 |
| AudioCaptureService | `start() / pause() / resume() / stop()` | 录音服务主接口 |
| RecordingSafeguards | `class` 含 `RecordingTimeout` + `AudioLevelMonitor` | 录音保护（超时 + 静音检测） |
| NativeAudioCapture | `abstract class` | Method Channel 桥接抽象接口（预留原生实现） |
| audioCaptureServiceProvider | `Provider<AudioCaptureService>` | Riverpod Provider |
| audioRecorderStateProvider | `StreamProvider<AudioRecorderState>` | 状态流 Provider |

---

## 内部结构

```
AudioRecorderStateNotifier (状态机)
    ↓ 驱动
AudioCaptureService (录音编排)
    ↓ 依赖
    ├── MicPermissionHandler (权限封装 → PermissionManager)
    ├── AudioRecorder (record 包)
    └── RecordingSafeguards (保护机制)
            ├── RecordingTimeout (60s 超时)
            └── AudioLevelMonitor (静音检测)

NativeAudioCapture (Method Channel 桥接，预留原生实现)
```

---

## 依赖

| 依赖模块 | 用途 |
|---------|------|
| core/common | 复用 PermissionManager 抽象 |
| record (v5.2.0) | 跨平台 PCM 录音 |
| path_provider (v2.1.4) | 临时文件路径 |
| flutter_riverpod | 状态管理注入 |
| dart:async | Timer、StreamController |
| dart:math | log10（RMS 计算） |
| dart:io | File（临时文件验证） |
