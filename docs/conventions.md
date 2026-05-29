# 编码规范

<!-- 本文档由人维护，定义项目的编码约定。agent 可读取作为参考，不修改。 -->

---

## 命名规范

| 类别 | 规范 | 示例 |
|------|------|------|
| 文件 | snake_case | `reminder_service.dart`、`group_model.dart` |
| 类 / 类型 | PascalCase | `ReminderService`、`AppDatabase` |
| 函数 / 方法 | camelCase | `createReminder()`、`validateTime()` |
| 常量 | lowerCamelCase | `maxRetryCount`、`defaultGroupName` |
| 私有成员 | 前缀 `_` | `_database`、`_handleError()` |
| 测试文件 | `<name>_test.dart` | `reminder_service_test.dart` |
| 模型文件 | `<name>_model.dart` | `group_model.dart`、`reminder_model.dart` |
| DAO 文件 | `<name>_dao.dart` | `group_dao.dart`、`reminder_dao.dart` |

---

## 目录结构

```
src/
├── core/
│   ├── common/               # 通用模块
│   │   ├── ARCHITECTURE.md
│   │   ├── CONSTRAINTS.md
│   │   ├── PROGRESS.md
│   │   └── code/
│   │       ├── constants/     # 全局常量
│   │       ├── models/        # 数据模型
│   │       ├── utils/         # 工具类、扩展方法
│   │       └── permissions/   # 权限管理
│   ├── database/              # 数据库模块
│   │   ├── code/
│   │   │   ├── database.dart          # AppDatabase 定义
│   │   │   ├── group_dao.dart         # 分组 DAO
│   │   │   ├── reminder_dao.dart      # 提醒 DAO
│   │   │   ├── tables/                # Drift 表定义
│   │   │   └── database.g.dart        # Drift 生成的代码
│   ├── voice/                 # 语音模块
│   │   └── code/
│   │       ├── voice_service.dart     # 对外接口
│   │       ├── recorder.dart          # 录音实现
│   │       ├── asr_bridge.dart        # ASR Method Channel 桥接
│   │       └── parser.dart            # 语义解析
│   ├── reminder/              # 提醒模块
│   │   └── code/
│   │       ├── reminder_service.dart  # 对外接口
│   │       ├── time_parser.dart       # 时间解析
│   │       └── scheduler.dart         # 系统闹钟调度
│   └── notification/          # 通知模块
│       └── code/
│           └── notification_service.dart
├── feature/
│   ├── home/                  # 首页
│   │   └── code/
│   │       ├── home_page.dart
│   │       └── widgets/       # 首页子组件
│   ├── voice_input/           # 语音录入页
│   │   └── code/
│   │       ├── voice_input_page.dart
│   │       └── widgets/
│   ├── group_manage/          # 分组管理页
│   │   └── code/
│   │       ├── group_manage_page.dart
│   │       └── widgets/
│   └── cleanup/               # 批量清理页
│       └── code/
│           ├── cleanup_page.dart
│           └── widgets/
└── main.dart                  # 应用入口
```

---

## Git 规范

### Commit Message

```
<type>(<scope>): <subject>

<body>
```

| 字段 | 说明 |
|------|------|
| type | feat / fix / refactor / test / docs / chore |
| scope | 模块名或功能 ID（如 `F-01`、`database`、`voice`） |
| subject | 一句话描述，中文 |

**示例**：
```
feat(F-01, database): 实现 groups 和 reminders 表的 Drift 定义

- 创建 groups 表（id, name, created_at, sort_order）
- 创建 reminders 表（id, content, remind_time, group_id, status, created_at）
- 生成对应的 DAO 和数据访问方法
```

```
test(F-02, reminder): 补充时间解析逻辑的边界条件测试

- 覆盖「下周」「半个月后」等口语时间
- 覆盖闰年、月末等边界日期
```

### 分支

- `main` — 受保护，仅通过 reviewed merge 进入
- `feature/<id>-<name>` — 功能分支，如 `feature/F-01-core-foundation`

---

## 测试规范

### 测试层级

| 层级 | 目录 | 覆盖范围 |
|------|------|---------|
| Unit | `test/unit/<module>/` | 单个函数 / 类的行为 |
| Integration | `test/integration/` | 跨模块交互（如数据库→提醒调度） |
| E2E | `test/e2e/` | 完整用户场景（如语音录入→通知触发） |

### 命名

```dart
group('ReminderService', () {
  group('schedule()', () {
    test('给定有效时间，应成功注册系统闹钟', () {
      // arrange / act / assert
    });

    test('给定已过期时间，应返回错误', () {
      // arrange / act / assert
    });
  });
});
```

### 覆盖率目标

- 数据库 CRUD：100% 覆盖率（所有增删改查路径）
- 时间解析：覆盖所有口语时间模式
- 语义解析：覆盖所有预期提取字段
- 集成测试：覆盖所有关键跨模块路径

---

## 错误处理

- **错误模型**：使用 `Result<T, AppError>` 模式或 Dart `sealed class`，所有公开方法返回明确类型，禁止裸 `throw`
- **错误码**：`AppError(code: "DB_001", message: "数据库写入失败")`
- **异常边界**：Service 层捕获所有异常并转为 Result，不让异常穿透到 UI
- **UI 层**：通过 Riverpod 的 `AsyncValue` 优雅处理 loading / error / data 三态

---

## Code Review 检查要点

1. 是否符合 `harness/ARCHITECTURE.md` 中的依赖方向（Feature 不能反向依赖 Core）
2. 是否违反 `harness/CONSTRAINTS.md` 中的硬约束（网络请求、权限声明、模型打包等）
3. 测试是否覆盖了正常路径和边界条件（时间解析边界、空数据、权限拒绝等）
4. 是否有调试代码残留（`print()`、`debugPrint()`、`// TODO` 注释）
5. Widget 是否直接访问了数据库（必须通过 Service/Repository 层）
6. 所有公开方法是否有文档注释
