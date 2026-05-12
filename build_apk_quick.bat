@echo off
echo ========================================
echo LifeLog Flutter - 快速构建 APK
echo ========================================
echo.

REM 设置 Flutter 路径
set PATH=C:\flutter\bin;%PATH%

REM 进入项目目录
cd /d D:\projects\lifelog-demo\react-app\flutter-app

echo [1/5] 检查 Flutter 环境...
flutter --version
if %errorLevel% NEQ 0 (
    echo [错误] Flutter 未正确配置
    pause
    exit /b 1
)
echo.

echo [2/5] 安装依赖...
flutter pub get
if %errorLevel% NEQ 0 (
    echo [错误] 依赖安装失败
    pause
    exit /b 1
)
echo.

echo [3/5] 生成 Drift 数据库代码...
flutter pub run build_runner build --delete-conflicting-outputs
if %errorLevel% NEQ 0 (
    echo [错误] 代码生成失败
    pause
    exit /b 1
)
echo.

echo [4/5] 运行测试...
flutter test
if %errorLevel% NEQ 0 (
    echo [警告] 测试失败，但继续构建
)
echo.

echo [5/5] 构建 APK...
flutter build apk --release --split-per-abi
if %errorLevel% NEQ 0 (
    echo [错误] APK 构建失败
    pause
    exit /b 1
)
echo.

echo ========================================
echo ✅ 构建完成！
echo ========================================
echo.
echo APK 文件位置:
echo build\app\outputs\flutter-apk\
echo.
echo 文件列表:
dir build\app\outputs\flutter-apk\*.apk /b
echo.
echo 推荐使用: app-arm64-v8a-release.apk
echo.
pause
