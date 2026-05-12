@echo off
echo ========================================
echo 监控 Flutter APK 构建进度
echo ========================================
echo.
echo 正在检查构建状态...
echo.

cd /d D:\projects\lifelog-demo\react-app\flutter-app

:loop
cls
echo ========================================
echo Flutter APK 构建监控
echo ========================================
echo 时间: %date% %time%
echo.

REM 检查是否有 APK 文件生成
if exist "build\app\outputs\flutter-apk\*.apk" (
    echo ✅ 构建完成！
    echo.
    echo APK 文件:
    dir build\app\outputs\flutter-apk\*.apk /b
    echo.
    echo 文件位置: build\app\outputs\flutter-apk\
    echo.
    pause
    exit /b 0
)

REM 检查构建进程
tasklist | findstr /i "dart.exe gradle" >nul
if %errorLevel% EQU 0 (
    echo 🔄 构建进行中...
    echo.
    echo 进程状态:
    tasklist | findstr /i "dart.exe gradle"
) else (
    echo ⚠️  未检测到构建进程
    echo.
    echo 可能的情况:
    echo 1. 构建已完成
    echo 2. 构建失败
    echo 3. 构建尚未开始
)

echo.
echo 按 Ctrl+C 退出监控
timeout /t 10 >nul
goto loop
