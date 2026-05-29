# 模块约束 — core/common

<!-- 模块级硬约束。implementer 每个单元完成后自检 -->

1. **禁止**引入 flutter_riverpod 依赖
2. **必须**保持纯 Dart 层，不依赖 Flutter Framework
3. **禁止** import feature 层任何模块
4. **禁止**使用 `print`、`debugger`、TODO 注释
5. **必须**所有公开 API 有文档注释
6. DateFormatter **仅**依赖 `intl` 包
7. PermissionManager **仅**提供抽象接口 + Stub，不触及原生方法通道
8. **必须**所有序列化方法健壮处理 null/类型不匹配
