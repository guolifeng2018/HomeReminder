/// 提醒表单页
///
/// 完整表单 UI：标题、内容、分组下拉、日期时间选择器、重复频率 SegmentedButton。
/// 接收可选 [reminderId] 区分新建/编辑模式。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/common/code/models/group_model.dart';
import '../../../core/common/code/models/enums.dart';
import '../../../core/providers/providers.dart';

/// 提醒表单页
///
/// 用于新建或编辑提醒。
/// [reminderId] 为 null 时进入新建模式，否则进入编辑模式。
class ReminderFormPage extends ConsumerStatefulWidget {
  /// 编辑模式下的提醒 ID（新建时为 null）
  final int? reminderId;

  const ReminderFormPage({super.key, this.reminderId});

  @override
  ConsumerState<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends ConsumerState<ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();

  // 文本控制器
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  // 表单状态
  Group? _selectedGroup;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  ReminderFrequency _selectedFrequency = ReminderFrequency.once;

  bool get _isEditMode => widget.reminderId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑提醒' : '添加提醒'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题
            TextFormField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: '标题',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '标题不能为空';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 内容
            TextFormField(
              controller: _contentController,
              maxLength: 200,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: '内容（可选）',
              ),
            ),
            const SizedBox(height: 16),

            // 分组下拉
            _buildGroupDropdown(),
            const SizedBox(height: 16),

            // 时间选择
            _buildTimePicker(),
            const SizedBox(height: 16),

            // 重复频率
            _buildFrequencySelector(),
            const SizedBox(height: 32),

            // 保存按钮
            ElevatedButton(
              onPressed: _onSubmit,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 分组下拉选择器
  Widget _buildGroupDropdown() {
    final groupsAsync = ref.watch(groupRepositoryProvider).getAll();

    return FutureBuilder<List<Group>>(
      future: groupsAsync,
      builder: (context, snapshot) {
        final groups = snapshot.data ?? [];
        return DropdownButtonFormField<Group>(
          value: _selectedGroup,
          items: groups
              .map((g) => DropdownMenuItem<Group>(
                    value: g,
                    child: Text(g.name),
                  ))
              .toList(),
          onChanged: (group) {
            setState(() => _selectedGroup = group);
          },
          decoration: const InputDecoration(
            labelText: '分组',
          ),
          validator: (value) {
            if (value == null) {
              return '请选择分组';
            }
            return null;
          },
        );
      },
    );
  }

  /// 时间选择器
  Widget _buildTimePicker() {
    final formatted = DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('提醒时间'),
      subtitle: Text(formatted),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDateTime,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date == null || !mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        );
        if (time == null || !mounted) return;

        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      },
    );
  }

  /// 重复频率选择器
  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('重复频率', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        SegmentedButton<ReminderFrequency>(
          segments: ReminderFrequency.values
              .map((f) => ButtonSegment<ReminderFrequency>(
                    value: f,
                    label: Text(f.displayName),
                  ))
              .toList(),
          selected: {_selectedFrequency},
          onSelectionChanged: (set) {
            setState(() => _selectedFrequency = set.first);
          },
        ),
      ],
    );
  }

  /// 提交处理：表单验证 + 时间校验
  void _onSubmit() {
    // 1. 表单字段校验
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. 时间校验
    if (_selectedDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('时间不能是过去')),
      );
      return;
    }

    // TODO: 数据库写入（后续单元实现）
  }
}
