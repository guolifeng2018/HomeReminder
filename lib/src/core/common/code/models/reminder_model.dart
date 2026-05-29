/// Reminder 数据模型
///
/// 提醒实体，包含提醒的基本信息、时间安排、状态和重复频率。
library;

import 'enums.dart';

/// 提醒实体
class Reminder {
  /// 提醒 ID（0 表示未持久化）
  final int id;

  /// 所属分组 ID
  final int groupId;

  /// 提醒标题
  final String title;

  /// 提醒内容（可选）
  final String? content;

  /// 计划时间
  final DateTime scheduledAt;

  /// 提醒状态
  final ReminderStatus status;

  /// 重复频率
  final ReminderFrequency frequency;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间（可选）
  final DateTime? updatedAt;

  const Reminder({
    this.id = 0,
    required this.groupId,
    required this.title,
    this.content,
    required this.scheduledAt,
    this.status = ReminderStatus.pending,
    this.frequency = ReminderFrequency.once,
    required this.createdAt,
    this.updatedAt,
  });

  /// 从 JSON Map 创建（字符串键，枚举用字符串值）
  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: _safeInt(json['id'], 0),
      groupId: _safeInt(json['group_id'], 0),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString(),
      scheduledAt: _safeDateTime(json['scheduled_at']),
      status: ReminderStatus.fromString(json['status']?.toString() ?? 'pending'),
      frequency: ReminderFrequency.fromString(
          json['frequency']?.toString() ?? 'once'),
      createdAt: _safeDateTime(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? _safeDateTime(json['updated_at'])
          : null,
    );
  }

  /// 序列化为 JSON Map（字符串键，枚举用 name 字符串）
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'group_id': groupId,
      'title': title,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status.name,
      'frequency': frequency.name,
      'created_at': createdAt.toIso8601String(),
    };
    if (content != null) {
      map['content'] = content;
    }
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toIso8601String();
    }
    return map;
  }

  /// 从 Map 创建（用于 Drift 数据库，时间字段用毫秒时间戳，枚举用 index）
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: _safeInt(map['id'], 0),
      groupId: _safeInt(map['group_id'], 0),
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString(),
      scheduledAt: _safeDateTime(map['scheduled_at']),
      status: _parseStatusFromMap(map['status']),
      frequency: _parseFrequencyFromMap(map['frequency']),
      createdAt: _safeDateTime(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? _safeDateTime(map['updated_at'])
          : null,
    );
  }

  /// 转换为 Map（用于 Drift 数据库，时间用毫秒时间戳，枚举用 index）
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'group_id': groupId,
      'title': title,
      'scheduled_at': scheduledAt.millisecondsSinceEpoch,
      'status': status.index,
      'frequency': frequency.index,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
    if (id != 0) {
      map['id'] = id;
    }
    if (content != null) {
      map['content'] = content;
    }
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.millisecondsSinceEpoch;
    }
    return map;
  }

  /// 创建副本（部分更新）
  Reminder copyWith({
    int? id,
    int? groupId,
    String? title,
    String? content,
    DateTime? scheduledAt,
    ReminderStatus? status,
    ReminderFrequency? frequency,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearContent = false,
    bool clearUpdatedAt = false,
  }) {
    return Reminder(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      content: clearContent ? null : (content ?? this.content),
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt:
          clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder &&
        other.id == id &&
        other.groupId == groupId &&
        other.title == title &&
        other.content == content &&
        other.scheduledAt == scheduledAt &&
        other.status == status &&
        other.frequency == frequency &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      groupId,
      title,
      content,
      scheduledAt,
      status,
      frequency,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Reminder(id: $id, groupId: $groupId, title: $title, '
        'content: $content, scheduledAt: $scheduledAt, status: $status, '
        'frequency: $frequency, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// 安全解析 int
int _safeInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// 安全解析 DateTime（ISO 8601 字符串或毫秒时间戳）
DateTime _safeDateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.now();
}

/// 从 Map 中解析 ReminderStatus（支持 index 或字符串）
ReminderStatus _parseStatusFromMap(dynamic value) {
  if (value is int) {
    return ReminderStatus.values[value.clamp(0, ReminderStatus.values.length - 1)];
  }
  if (value is String) {
    return ReminderStatus.fromString(value);
  }
  return ReminderStatus.pending;
}

/// 从 Map 中解析 ReminderFrequency（支持 index 或字符串）
ReminderFrequency _parseFrequencyFromMap(dynamic value) {
  if (value is int) {
    return ReminderFrequency
        .values[value.clamp(0, ReminderFrequency.values.length - 1)];
  }
  if (value is String) {
    return ReminderFrequency.fromString(value);
  }
  return ReminderFrequency.once;
}
