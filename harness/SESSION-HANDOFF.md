# 会话交接

---

## 下一个 Agent

- **角色**：reviewer
- **任务摘要**：验证 F-09（模型下载管理）交付物
- **技能文件**：agents/reviewer/SKILL.md

---

## 仓库状态

- **核心功能**：F-00 ~ F-08 已完成并验证（F-08 代码在 F-07 模块中）
- **当前功能**：F-09（模型下载管理）— 代码完成，implementer 已交付
- **待开发 P0**：F-10 ~ F-13
- **待开发 P1**：F-14 ~ F-20
- **构建状态**：`flutter analyze` 暂时无法运行（Flutter SDK 权限问题），reviewer 需解决后执行 L1
- **测试状态**：暂时无法运行（同上），reviewer 需解决后执行 L2/L3
- **已知缺口**：
  - F-10 ~ F-15 仅有占位符页面（F-10/11/12 voice 模块完全为空）
  - F-04 路由测试缺少 replace() 导航和 /group/ 空路径边界用例

---

## F-09 交付物清单

| 文件 | 行数 | 说明 |
|------|------|------|
| `lib/src/core/common/code/download/model_registry.dart` | 131 | DownloadableModel + ModelRegistry（2 模型） |
| `lib/src/core/common/code/download/downloader.dart` | 224 | HTTP Range 断点续传 + .part 写入 |
| `lib/src/core/common/code/download/sha256_validator.dart` | 89 | SHA256 校验 + 3 次重试 |
| `lib/src/core/common/code/download/storage_checker.dart` | 120 | 存储空间检查（df + fallback） |
| `lib/src/core/common/code/download/download_state.dart` | 197 | 5 状态枚举 + DownloadProgress + StateManager |
| `lib/src/core/common/code/download/model_download_service.dart` | 237 | 编排服务（协调全部组件） |
| `lib/src/core/common/code/download/download_providers.dart` | 51 | Riverpod Provider 层 |
| `lib/src/core/common/common.dart` | +9 | barrel 导出 download 模块 |
| `lib/src/feature/model_download/code/model_download_page.dart` | 283 | UI 页（ConsumerStatefulWidget） |

---

## 快速启动

1. 读取 `agents/reviewer/SKILL.md`
2. 解决 Flutter SDK 权限问题后运行 `flutter analyze`（L1）
3. 运行 `flutter test test/unit/`（L2）
4. 运行 `flutter test test/integration/`（L3）
5. 出 `work/reviewer/L1-REPORT.md` / `L2-REPORT.md` / `L3-REPORT.md`
6. 更新本文件「下一个 Agent」指向下一个角色
