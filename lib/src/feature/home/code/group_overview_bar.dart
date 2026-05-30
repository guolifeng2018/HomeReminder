/// 分组卡片横向列表
///
/// 水平滚动的分组概览卡片列表，支持 loading/空数据/有数据三态。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/common/code/models/group_model.dart';
import 'group_overview_card.dart';

/// 分组卡片横向列表
///
/// 接收 [groups] (AsyncValue) 和已计算的分组计数映射。
class GroupOverviewBar extends StatelessWidget {
  /// 分组列表（AsyncValue）
  final AsyncValue<List<Group>> groups;

  /// 待处理数量映射（groupId → count）
  final Map<int, int> pendingCounts;

  /// 已完成数量映射（groupId → count）
  final Map<int, int> completedCounts;

  const GroupOverviewBar({
    super.key,
    required this.groups,
    this.pendingCounts = const {},
    this.completedCounts = const {},
  });

  @override
  Widget build(BuildContext context) {
    return groups.when(
      data: (groupList) {
        if (groupList.isEmpty) {
          return _buildEmptyPlaceholder(context);
        }
        return _buildGroupList(context, groupList);
      },
      loading: () => _buildLoadingPlaceholder(),
      error: (error, _) => _buildErrorPlaceholder(error.toString()),
    );
  }

  /// 加载中占位
  Widget _buildLoadingPlaceholder() {
    return SizedBox(
      height: 130,
      child: Center(
        child: SizedBox(
          width: 130,
          height: 110,
          child: Card(
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }

  /// 空数据占位
  Widget _buildEmptyPlaceholder(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Center(
        child: SizedBox(
          width: 140,
          height: 110,
          child: Card(
            child: Center(
              child: Text(
                '暂无分组',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 错误占位
  Widget _buildErrorPlaceholder(String error) {
    return SizedBox(
      height: 130,
      child: Center(
        child: Text(
          '加载失败',
          style: TextStyle(color: Colors.red.shade400),
        ),
      ),
    );
  }

  /// 分组卡片列表
  Widget _buildGroupList(BuildContext context, List<Group> groupList) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: groupList.length,
        itemBuilder: (context, index) {
          final group = groupList[index];
          final pending = pendingCounts[group.id] ?? 0;
          final completed = completedCounts[group.id] ?? 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GroupOverviewCard(
              group: group,
              pendingCount: pending,
              completedCount: completed,
            ),
          );
        },
      ),
    );
  }
}
