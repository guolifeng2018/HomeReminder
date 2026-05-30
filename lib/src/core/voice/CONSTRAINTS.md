# 模块约束

<!-- 由 implementer 填写。本模块的硬约束，用"必须/禁止"语言。 -->
<!-- implementer 每完成一个单元后自检这些规则。reviewer L1 对照检查。 -->

---

## 数据约束

1. **必须**输出原始 PCM 格式（16kHz/16bit/mono），禁止输出 WAV 或其他容器格式
2. **禁止**在录音过程中修改采样率、比特率、声道数等配置参数

---

## 接口约束

1. **禁止**本模块内任何文件 import `feature/` 层模块
2. **必须**通过 `PermissionManager` 抽象接口请求权限，禁止直接调用平台 API
3. **禁止** NativeAudioCapture 的 Dart stub 实现调用实际 Method Channel（留到 F-17/F-18）

---

## 性能约束

1. **必须**单次录音时长不超过 60 秒（超时自动停止）
2. **必须**静音检测每 200ms 计算一次 RMS，禁止更短间隔（避免 CPU 浪费）

---

## 状态机约束

1. **必须**遵守状态转换规则：idle→recording→paused→recording→stopped，任意状态→error
2. **禁止**非法状态转换（idle→paused、stopped→recording 等），必须抛出 StateError
