/// Group 数据模型
///
/// 分组实体，用于组织家庭清洁事务。
/// 支持预设分组和用户自定义分组。
library;

/// 分组实体
class Group {
  /// 分组 ID（0 表示未持久化）
  final int id;

  /// 分组名称
  final String name;

  /// 分组图标标识
  final String? icon;

  /// 是否为预设分组（不可删除）
  final bool isPreset;

  /// 排序权重
  final int sortOrder;

  /// 创建时间
  final DateTime createdAt;

  const Group({
    this.id = 0,
    required this.name,
    this.icon,
    this.isPreset = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  /// 从 JSON Map 创建（字符串键）
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: _parseInt(json['id'], 0),
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
      isPreset: _parseBool(json['is_preset'], false),
      sortOrder: _parseInt(json['sort_order'], 0),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  /// 序列化为 JSON Map（字符串键）
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'is_preset': isPreset,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
    if (icon != null) {
      map['icon'] = icon;
    }
    return map;
  }

  /// 从 Map 创建（用于 Drift 数据库交互，字段名用 snake_case）
  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: _parseInt(map['id'], 0),
      name: map['name']?.toString() ?? '',
      icon: map['icon']?.toString(),
      isPreset: _parseBool(map['is_preset'], false),
      sortOrder: _parseInt(map['sort_order'], 0),
      createdAt: _parseDateTimeOrNow(map['created_at']),
    );
  }

  /// 转换为 Map（用于 Drift 数据库，created_at 用毫秒时间戳）
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'is_preset': isPreset ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
    if (id != 0) {
      map['id'] = id;
    }
    if (icon != null) {
      map['icon'] = icon;
    }
    return map;
  }

  /// 创建副本（部分更新）
  Group copyWith({
    int? id,
    String? name,
    String? icon,
    bool? isPreset,
    int? sortOrder,
    DateTime? createdAt,
    bool clearIcon = false,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: clearIcon ? null : (icon ?? this.icon),
      isPreset: isPreset ?? this.isPreset,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group &&
        other.id == id &&
        other.name == name &&
        other.icon == icon &&
        other.isPreset == isPreset &&
        other.sortOrder == sortOrder &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, icon, isPreset, sortOrder, createdAt);
  }

  @override
  String toString() {
    return 'Group(id: $id, name: $name, icon: $icon, isPreset: $isPreset, '
        'sortOrder: $sortOrder, createdAt: $createdAt)';
  }
}

/// 安全解析 int（容错）
int _parseInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// 安全解析 bool（容错）
bool _parseBool(dynamic value, bool fallback) {
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    final lower = value.toLowerCase().trim();
    return lower == 'true' || lower == '1';
  }
  return fallback;
}

/// 安全解析 DateTime（ISO 8601 字符串）
DateTime _parseDateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.now();
}

/// 安全解析 DateTime（int 毫秒时间戳或缺省用 now）
DateTime _parseDateTimeOrNow(dynamic value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
