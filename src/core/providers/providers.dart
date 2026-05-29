/// core/providers 模块 barrel file
///
/// 统一导出所有 Provider、服务抽象、配置模型，供上层模块使用。
library;

// 配置模型
export 'code/app_config.dart';

// 服务抽象接口 + stub
export 'code/reminder_service.dart';
export 'code/notification_service.dart';
export 'code/voice_service.dart';

// 数据层 Provider
export 'code/database_providers.dart';

// 服务层 Provider
export 'code/service_providers.dart';

// 配置 Provider
export 'code/app_config_provider.dart';
