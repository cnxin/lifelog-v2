# Android SDK 配置指南

## 问题
Flutter 找不到 Android SDK 命令行工具（cmdline-tools）

## 解决步骤

### 1. 打开 Android Studio

启动 Android Studio

### 2. 打开 SDK Manager

**方法 A：从欢迎界面**
- 点击右上角的 ⚙️ (Configure) 或 More Actions
- 选择 "SDK Manager"

**方法 B：从项目界面**
- 顶部菜单：Tools → SDK Manager
- 或者：File → Settings → Appearance & Behavior → System Settings → Android SDK

### 3. 安装必需组件

在 SDK Manager 中：

#### SDK Platforms 标签页
- ✅ 勾选 **Android 14.0 (API 34)** 或更高版本
- ✅ 勾选 **Android 13.0 (API 33)**（推荐）

#### SDK Tools 标签页
- ✅ 勾选 **Android SDK Build-Tools**
- ✅ 勾选 **Android SDK Command-line Tools (latest)**  ⭐ 重要！
- ✅ 勾选 **Android SDK Platform-Tools**
- ✅ 勾选 **Android Emulator**（可选）

### 4. 应用更改

- 点击 "Apply" 或 "OK"
- 等待下载和安装完成（约 5-10 分钟）

### 5. 接受许可协议

安装完成后，打开命令提示符：

```cmd
flutter doctor --android-licenses
```

按 `y` 接受所有许可协议

### 6. 验证配置

```cmd
flutter doctor
```

应该看到：
```
[✓] Android toolchain - develop for Android devices
```

### 7. 构建 APK

```cmd
cd D:\projects\lifelog-demo\react-app\flutter-app
flutter build apk --release --split-per-abi
```

## 常见问题

### Q: 找不到 SDK Manager
A: 确保 Android Studio 已完全启动，从欢迎界面右上角的齿轮图标进入

### Q: 下载很慢
A: 可以配置国内镜像，或者使用 VPN

### Q: 许可协议接受失败
A: 以管理员身份运行命令提示符，然后重新执行 `flutter doctor --android-licenses`

## 预计时间

- SDK 下载安装：5-10 分钟
- 接受许可：1 分钟
- 首次 APK 构建：5-10 分钟

---

**完成后请告诉我，我会继续帮您构建 APK！**
