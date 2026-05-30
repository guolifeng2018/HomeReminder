/// 分组概览卡片
///
/// 显示分组图标+名称、待办数量 Badge、完成率环形进度。
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/common/code/models/group_model.dart';

/// 分组概览卡片
///
/// 接收 Group + pendingCount + completedCount，卡片宽 140。
class GroupOverviewCard extends StatelessWidget {
  /// 分组数据
  final Group group;

  /// 待处理数量
  final int pendingCount;

  /// 已完成数量
  final int completedCount;

  const GroupOverviewCard({
    super.key,
    required this.group,
    required this.pendingCount,
    required this.completedCount,
  });

  /// 图标名称 → IconData 映射
  static IconData _iconFor(String? iconName) {
    const map = <String, IconData>{
      'living': Icons.weekend,
      'livingroom': Icons.weekend,
      'bedroom': Icons.bed,
      'kitchen': Icons.kitchen,
      'fridge': Icons.kitchen_outlined,
      'vacuum': Icons.cleaning_services,
      'floor': Icons.grid_view,
      'cleaning': Icons.cleaning_services,
      'bathroom': Icons.bathtub,
      'balcony': Icons.balcony,
      'garden': Icons.yard,
      'pet': Icons.pets,
      'laundry': Icons.local_laundry_service,
      'office': Icons.computer,
      'car': Icons.directions_car,
    };
    return map[iconName?.toLowerCase()] ?? Icons.folder_outlined;
  }

  /// 完成率
  double get _completionRatio {
    final total = pendingCount + completedCount;
    if (total == 0) return 0.0;
    return completedCount / total;
  }

  /// 完成率百分比
  int get _percentage => (_completionRatio * 100).round();

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(group.icon);
    final ratio = _completionRatio;

    return SizedBox(
      width: 140,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标 + 待办 Badge
              Stack(
                children: [
                  Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
                  if (pendingCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 分组名
              Text(
                group.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              // 环形进度
              SizedBox(
                width: 48,
                height: 48,
                child: CustomPaint(
                  painter: CompletionRingPainter(ratio: ratio),
                  child: Center(
                    child: Text(
                      '$_percentage%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 完成率环形进度 Painter
///
/// 背景弧灰色 270°，前景弧蓝色按比例。
class CompletionRingPainter extends CustomPainter {
  final double ratio;

  CompletionRingPainter({required this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;

    const startAngle = math.pi * 1.25; // 225° (bottom-left start)
    const sweepAngle = math.pi * 1.5; // 270°

    // 背景弧
    final bgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // 前景弧
    final fgPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * ratio,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CompletionRingPainter oldDelegate) {
    return oldDelegate.ratio != ratio;
  }
}
