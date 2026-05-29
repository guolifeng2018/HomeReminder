/// 应用常量定义
///
/// 包含应用名称、预设分组列表、时间格式模板等全局常量。
/// 所有常量不可变，确保应用行为一致性。
library;

/// 应用名称
const String appName = '居净清单';

/// 时间格式模板
const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
const String dateFormat = 'yyyy-MM-dd';
const String timeFormat = 'HH:mm';
const String displayDateFormat = 'yyyy年M月d日';
const String displayDateTimeFormat = 'MM月dd日 HH:mm';
const String weekdayFormat = 'EEEE';

/// 预设分组列表
///
/// 六组内置分组，用户不可删除但可编辑名称和图标。
/// sort_order 用于排序，id 为预设标识（1-6）。
const List<Map<String, dynamic>> defaultGroups = [
  {
    'id': 1,
    'name': '客厅',
    'icon': 'living',
    'is_preset': true,
    'sort_order': 0,
  },
  {
    'id': 2,
    'name': '卧室',
    'icon': 'bedroom',
    'is_preset': true,
    'sort_order': 1,
  },
  {
    'id': 3,
    'name': '厨房',
    'icon': 'kitchen',
    'is_preset': true,
    'sort_order': 2,
  },
  {
    'id': 4,
    'name': '冰箱',
    'icon': 'fridge',
    'is_preset': true,
    'sort_order': 3,
  },
  {
    'id': 5,
    'name': '扫地机',
    'icon': 'vacuum',
    'is_preset': true,
    'sort_order': 4,
  },
  {
    'id': 6,
    'name': '地面',
    'icon': 'floor',
    'is_preset': true,
    'sort_order': 5,
  },
];
