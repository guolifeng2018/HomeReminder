#!/bin/bash
set -e

echo "=== 居净清单 (JuJingList) 环境初始化 ==="

# ============================================================
# 1. 环境依赖检查
# ============================================================

# 1.1 Flutter SDK
echo "[CHECK] Flutter SDK ..."
FLUTTER_PATH=$(which flutter 2>/dev/null || echo "")
if [ -z "$FLUTTER_PATH" ]; then
    echo "[MISSING] Flutter — 未找到 flutter 命令"
    echo "  安装指引：https://docs.flutter.dev/get-started/install/macos"
    exit 1
fi

FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 || echo "")
if [ -z "$FLUTTER_VER" ]; then
    # Flutter 命令存在但执行失败，可能是权限问题
    echo "[FAIL] Flutter 命令可找到但无法执行"
    FLUTTER_DIR=$(dirname "$(dirname "$FLUTTER_PATH")")
    echo "  可能原因：SDK 目录权限不足"
    echo "  修复命令：sudo chown -R \$(whoami) \"$FLUTTER_DIR\""
    echo "  然后重新运行本脚本"
    exit 1
fi

echo "[OK] Flutter — $FLUTTER_VER"

# 1.2 Dart SDK
echo "[CHECK] Dart SDK ..."
DART_VER=$(dart --version 2>/dev/null || echo "")
if [ -z "$DART_VER" ]; then
    echo "[MISSING] Dart — 未找到 dart 命令（Flutter SDK 自带 Dart，请检查 Flutter 安装）"
    exit 1
fi
echo "[OK] Dart — $DART_VER"

# 1.3 Git
echo "[CHECK] Git ..."
GIT_VER=$(git --version 2>/dev/null || echo "")
if [ -z "$GIT_VER" ]; then
    echo "[MISSING] Git — 请安装 Git：https://git-scm.com"
    exit 1
fi
echo "[OK] Git — $GIT_VER"

# 1.4 Xcode CLI (macOS 必须，Linux 跳过)
echo "[CHECK] Xcode CLI ..."
if [ "$(uname -s)" = "Darwin" ]; then
    XCODE_PATH=$(xcode-select -p 2>/dev/null || echo "")
    if [ -z "$XCODE_PATH" ]; then
        echo "[MISSING] Xcode CLI — 请运行：xcode-select --install"
        exit 1
    fi
    echo "[OK] Xcode CLI — $XCODE_PATH"
else
    echo "[SKIP] Xcode CLI（非 macOS 平台）"
fi

# 1.5 Android SDK（通过 flutter doctor 检查）
echo "[CHECK] Android SDK ..."
if flutter doctor 2>/dev/null | grep -q "Android toolchain"; then
    ANDROID_STATUS=$(flutter doctor 2>/dev/null | grep "Android toolchain" | head -1)
    echo "[INFO] $ANDROID_STATUS"
    if echo "$ANDROID_STATUS" | grep -q "No issues"; then
        echo "[OK] Android SDK 就绪"
    else
        echo "[WARN] Android SDK 有问题，请运行 'flutter doctor' 查看详情"
        echo "  不影响 iOS 开发，但 Android 构建可能失败"
    fi
else
    echo "[SKIP] Android SDK（无法检测，不影响 iOS 构建）"
fi

# ============================================================
# 2. Flutter 项目初始化（如不存在）
# ============================================================
echo "[CHECK] Flutter 项目 ..."
if [ ! -f "pubspec.yaml" ]; then
    echo "[INFO] Flutter 项目不存在，创建中 ..."
    flutter create --org com.homeclean --project-name home_reminder .
    # 清理 flutter create 生成的默认 lib/ 目录（本项目使用 src/ 结构）
    if [ -d "lib" ]; then
        # 仅删除 flutter create 生成的模板代码，保留目录的兼容性
        rm -f lib/main.dart 2>/dev/null || true
    fi
    echo "[OK] Flutter 项目已创建"
else
    echo "[OK] Flutter 项目已存在"
fi

# ============================================================
# 3. 安装项目依赖
# ============================================================
echo "[RUN] flutter pub get ..."
flutter pub get
echo "[OK] flutter pub get"

# ============================================================
# 4. Drift 代码生成
# ============================================================
echo "[RUN] build_runner 代码生成 ..."
dart run build_runner build --delete-conflicting-outputs
echo "[OK] build_runner 代码生成"

# ============================================================
# 5. 平台权限配置检查
# ============================================================
echo "[CHECK] 平台权限配置 ..."

# Android 权限检查
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    MANIFEST="android/app/src/main/AndroidManifest.xml"
    MISSING_PERMS=""

    if ! grep -q "RECORD_AUDIO" "$MANIFEST" 2>/dev/null; then
        MISSING_PERMS="$MISSING_PERMS RECORD_AUDIO"
    fi
    if ! grep -q "POST_NOTIFICATIONS" "$MANIFEST" 2>/dev/null; then
        MISSING_PERMS="$MISSING_PERMS POST_NOTIFICATIONS"
    fi
    if ! grep -q "READ_EXTERNAL_STORAGE" "$MANIFEST" 2>/dev/null; then
        MISSING_PERMS="$MISSING_PERMS READ_EXTERNAL_STORAGE"
    fi

    if [ -n "$MISSING_PERMS" ]; then
        echo "[WARN] Android 权限声明缺失：$MISSING_PERMS"
        echo "  请在 $MANIFEST 中 <manifest> 内 <application> 之前添加："
        for perm in $MISSING_PERMS; do
            echo "    <uses-permission android:name=\"android.permission.${perm}\"/>"
        done
    else
        echo "[OK] Android 权限声明完整"
    fi
else
    echo "[WARN] AndroidManifest.xml 未找到（Android 项目可能未生成）"
fi

# iOS 权限检查
if [ -f "ios/Runner/Info.plist" ]; then
    PLIST="ios/Runner/Info.plist"
    MISSING_DESC=""

    if ! grep -q "NSMicrophoneUsageDescription" "$PLIST" 2>/dev/null; then
        MISSING_DESC="$MISSING_DESC NSMicrophoneUsageDescription"
    fi

    if [ -n "$MISSING_DESC" ]; then
        echo "[WARN] iOS 权限描述缺失：$MISSING_DESC"
        echo "  请在 $PLIST 中添加："
        echo "    <key>NSMicrophoneUsageDescription</key>"
        echo "    <string>需要麦克风权限用于语音录入提醒事项</string>"
    else
        echo "[OK] iOS 权限描述完整"
    fi
else
    echo "[WARN] Info.plist 未找到（iOS 项目可能未生成）"
fi

# ============================================================
# 6. 创建必要目录
# ============================================================
echo "[RUN] 创建目录结构 ..."
mkdir -p test/unit test/integration test/e2e
mkdir -p work/logs/tests
echo "[OK] 目录结构"

echo ""
echo "=== 初始化完成 ==="
