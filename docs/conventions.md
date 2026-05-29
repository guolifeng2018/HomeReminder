# 编码规范

<!-- 本文档由人维护，定义项目的编码约定。agent 可读取作为参考，不修改。 -->

---

## 命名规范

| 类别 | 规范 | 示例 |
|------|------|------|
| 文件 | <!-- 如 snake_case --> | <!-- 如 auth_service.dart --> |
| 类 / 类型 | <!-- 如 PascalCase --> | <!-- 如 AuthService --> |
| 函数 / 方法 | <!-- 如 camelCase --> | <!-- 如 validateToken() --> |
| 常量 | <!-- 如 SCREAMING_SNAKE_CASE --> | <!-- 如 MAX_RETRY_COUNT --> |
| 测试文件 | <!-- 如 <name>_test.dart --> | <!-- 如 auth_service_test.dart --> |

---

## 目录结构

<!-- 说明每个目录的用途和放什么文件 -->

```
src/<module>/
├── ARCHITECTURE.md     # 模块架构文档
├── CONSTRAINTS.md      # 模块约束
├── PROGRESS.md         # 模块进度
└── code/               # 源代码
    ├── <module>_service.<ext>     # 对外接口
    ├── <module>_repository.<ext>  # 数据访问层
    └── models/                    # 数据模型
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
| scope | 模块名或功能 ID（如 `F-03`、`auth`） |
| subject | 一句话描述，中文 |

**示例**：
```
feat(F-03, auth): 实现 JWT token 刷新逻辑

- token 过期前 5 分钟自动刷新
- 刷新失败时清除本地 token 并跳转登录页
```

### 分支

<!-- 如 main / develop / feature/<id>-<name> -->

---

## 测试规范

### 测试层级

| 层级 | 目录 | 覆盖范围 |
|------|------|---------|
| Unit | `test/unit/<module>/` | 单个函数 / 类的行为 |
| Integration | `test/integration/` | 跨模块交互 |
| E2E | `test/e2e/` | 完整用户场景 |

### 命名

```
describe('<功能描述>', () {
  test('<场景>：<预期行为>', () {
    // arrange / act / assert
  });
});
```

### 覆盖率目标

<!-- 如 单元测试 >= 80%，集成测试覆盖所有关键路径 -->

---

## 错误处理

<!-- 统一错误处理模式，agent 必须遵守 -->

- **错误模型**：<!-- 如 所有公开方法返回 Result<T, AppError>，禁止裸 throw -->
- **错误码**：<!-- 如 AppError(code: "AUTH_001", message: "token 过期") -->
- **异常边界**：<!-- 如 Service 层捕获所有异常并转为 Result，不让异常穿透到 UI -->

---

## Code Review

<!-- 人审时的检查要点 -->

1. <!-- 是否符合架构文档中的依赖方向 -->
2. <!-- 是否违反 CONSTRAINTS.md 中的硬约束 -->
3. <!-- 测试是否覆盖了正常路径和边界条件 -->
4. <!-- 是否有调试代码残留 -->
