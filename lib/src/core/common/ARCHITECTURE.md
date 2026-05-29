# 模块架构 — core/common

## 职责

提供全局常量、数据模型、通用工具类和权限管理抽象接口。本模块为纯 Dart 层，不依赖 Flutter 框架或 Riverpod。

## 目录结构

```
code/
├── constants/
│   └── app_constants.dart     # 全局常量
├── models/
│   ├── enums.dart              # 枚举定义
│   ├── group_model.dart        # Group 数据模型
│   └── reminder_model.dart     # Reminder 数据模型
├── utils/
│   ├── date_formatter.dart     # 自然语言时间解析
│   └── string_sanitizer.dart   # 输入清洗
└── permissions/
    ├── permission_manager.dart       # 权限管理抽象类
    └── permission_manager_stub.dart  # Stub 实现

common.dart  # Barrel file 统一导出
```

## 对外接口

通过 `common.dart` barrel file 统一导出所有公开类型和函数。

## 依赖

- `intl` 包（仅 DateFormatter 使用）
- 无 flutter_riverpod 依赖
- 无 Flutter Framework 依赖
- 无 feature 层依赖
