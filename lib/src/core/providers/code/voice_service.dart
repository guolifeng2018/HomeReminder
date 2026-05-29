/// VoiceService 抽象接口 + Stub 实现
///
/// 语音识别服务：录音/ASR 识别。
/// 真实实现留给 F-10（core/voice）。
library;

/// 语音服务抽象接口
abstract class VoiceService {
  /// 开始监听，返回识别文本
  Future<String> startListening();

  /// 停止监听
  Future<void> stopListening();
}

/// VoiceService stub 实现
///
/// 所有方法抛出 [UnimplementedError]，后续模块通过
/// ProviderScope.overrides 替换为真实实现。
class StubVoiceService implements VoiceService {
  @override
  Future<String> startListening() {
    throw UnimplementedError('F-03 stub: VoiceService.startListening');
  }

  @override
  Future<void> stopListening() {
    throw UnimplementedError('F-03 stub: VoiceService.stopListening');
  }
}
