/// core/common 模块统一导出
///
/// 使用本文件即可导入本模块的全部公开接口。
/// 无需单独导入各子模块。
library;

// 常量
export 'code/constants/app_constants.dart';

// 数据模型
export 'code/models/enums.dart';
export 'code/models/group_model.dart';
export 'code/models/reminder_model.dart';

// 工具类
export 'code/utils/date_formatter.dart';
export 'code/utils/string_sanitizer.dart';

// 权限管理
export 'code/permissions/permission_manager.dart';
export 'code/permissions/permission_manager_stub.dart';
