/// 应用角标管理器
///
/// 管理应用桌面图标上的 Badge 计数。
/// 封装 flutter_app_badger 的 API，提供边界处理和降级逻辑。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

/// 角标操作抽象接口（用于测试注入）
abstract class BadgeOperator {
  /// 更新角标计数
  Future<void> updateBadgeCount(int count);

  /// 移除角标
  Future<void> removeBadge();

  /// 检查是否支持角标
  Future<bool> isSupported();
}

/// 真实角标操作实现（生产环境使用）
class RealBadgeOperator implements BadgeOperator {
  @override
  Future<void> updateBadgeCount(int count) {
    return FlutterAppBadger.updateBadgeCount(count);
  }

  @override
  Future<void> removeBadge() {
    return FlutterAppBadger.removeBadge();
  }

  @override
  Future<bool> isSupported() {
    return FlutterAppBadger.isAppBadgeSupported();
  }
}

/// 应用角标管理器
///
/// 根据待处理数量和过期数量计算并更新应用角标。
/// 处理 0/N/上限等边界场景。
class BadgeManager {
  /// 角标最大显示值
  static const int maxBadgeCount = 99;

  final BadgeOperator _operator;

  /// 创建 [BadgeManager]
  ///
  /// [badgeOperator] 可选，用于测试注入，默认使用 [RealBadgeOperator]。
  BadgeManager({BadgeOperator? badgeOperator})
      : _operator = badgeOperator ?? RealBadgeOperator();

  /// 更新角标
  ///
  /// [pendingCount] 待处理提醒数量
  /// [overdueCount] 已过期提醒数量
  ///
  /// badge = pendingCount + overdueCount
  /// - badge ≤ 0 → 移除角标
  /// - badge > 0 → 更新角标数（最大 [maxBadgeCount]）
  Future<void> updateBadge(int pendingCount, int overdueCount) async {
    final badge = _calculateBadge(pendingCount, overdueCount);

    try {
      if (badge <= 0) {
        await _operator.removeBadge();
      } else {
        await _operator.updateBadgeCount(badge);
      }
    } catch (e, stack) {
      debugPrint('BadgeManager: 角标更新失败: $e\n$stack');
    }
  }

  /// 获取当前应设置的角标数（不实际更新）
  int calculateBadge(int pendingCount, int overdueCount) {
    return _calculateBadge(pendingCount, overdueCount);
  }

  int _calculateBadge(int pendingCount, int overdueCount) {
    // 处理负数输入
    final safePending = pendingCount < 0 ? 0 : pendingCount;
    final safeOverdue = overdueCount < 0 ? 0 : overdueCount;

    final total = safePending + safeOverdue;
    if (total <= 0) return 0;
    if (total > maxBadgeCount) return maxBadgeCount;
    return total;
  }
}
