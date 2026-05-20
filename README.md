# LifeLog v2

LifeLog v2 是一个基于 Flutter + Material Design 3 的生活记录应用，用于把人物、地点和回忆串联成可检索、可回顾、可备份的本地生活档案。

项目从原 React/Capacitor 版本迁移而来，当前重点是移动端体验、本地优先存储、照片记录、提醒和数据可迁移性。

## 功能特性

### 核心记录
- 人物管理：姓名、昵称、关系、生日、纪念日、喜好、禁忌、备注和收藏。
- 地点管理：城市、区域、商场、店铺、评分、地址、坐标、地图链接、平台链接、照片、标签和收藏。
- 回忆管理：标题、日期、关联人物、关联地点、心情、正文、标签和照片。
- 日历视图：聚合生日、纪念日和回忆事件，支持农历信息展示。
- 账号与数据管理：本地账号说明、数据统计、完整 JSON 备份导出/导入、演示数据重置。

### v2 补齐功能
- 地点重复检测：按城市、商场、店名、地址、坐标等规则识别强重复和待确认重复。
- 地点合并：保留信息更完整的地点记录，合并标签、照片、外部链接、评分和备注。
- 合并撤销：保存地点合并前快照，可撤销最近一次合并。
- 回忆高级筛选：按人物、地点、心情、标签组合筛选，搜索覆盖标题、正文、人物、地点、心情和标签。
- 备份兼容：完整备份包含设置、提醒配置和地点合并历史。
- 关系维护看板：首页按最近互动、联系间隔和共同回忆识别需要关注的人。
- 人物关系摘要：人物详情展示最近互动、互动次数、关系状态和常去地点。
- 导入预览：从剪贴板恢复前先解析备份内容，展示人物、地点、回忆、照片索引、设置和提醒配置。

### 移动端体验
- 照片管理：相册/相机选择，本地保存，自动压缩，网格预览和全屏查看。
- 智能提醒：生日/纪念日提醒、定期联系提醒、往年今日回忆提醒。
- 主题系统：多套配色、暗色模式、Glass UI 卡片和渐变背景。
- 深度链接路由：人物、地点、回忆详情和编辑页可直接进入。

## 技术栈

| 层级 | 技术 |
|------|------|
| 应用框架 | Flutter |
| 状态管理 | Riverpod |
| 路由 | go_router |
| 本地数据库 | Drift + SQLite |
| Web 预览存储 | SharedPreferences 状态镜像 |
| 本地通知 | flutter_local_notifications + timezone |
| 图片 | image_picker + flutter_image_compress |
| 农历 | lunar |

## 快速开始

当前仓库默认分支为 `main`。

```powershell
git clone https://github.com/cnxin/lifelog-v2.git
cd lifelog-v2
D:\flutter\bin\flutter.bat pub get
D:\flutter\bin\flutter.bat analyze
D:\flutter\bin\flutter.bat test
```

如果 Flutter 已加入 PATH，也可以直接使用：

```bash
flutter pub get
flutter analyze
flutter test
```

## 运行

```bash
flutter run -d android
flutter run -d chrome
```

## 构建 Android APK

```bash
flutter build apk --release
```

输出文件：

```text
build/app/outputs/flutter-apk/app-release.apk
```

本仓库也会把发布包归档到 `releases/`，文件名格式示例：

```text
releases/lifelog-v0.3.1+45.apk
```

## 项目结构

```text
lib/
  app.dart                         # 路由和应用壳
  main.dart                        # 启动入口
  models/
    person.dart                    # 人物模型
    lifelog_models.dart            # 地点、回忆、备份和合并历史模型
  database/
    app_database.dart              # Drift 数据库
    tables.dart                    # 表定义
    database_helper.dart           # 平台条件导出
    database_helper_native.dart    # Android/iOS SQLite 数据访问
    database_helper_web.dart       # Web 预览数据访问
  pages/
    home_page.dart
    people_list_page.dart
    person_detail_page.dart
    person_form_page.dart
    places_list_page.dart
    place_detail_page.dart
    place_form_page.dart
    memories_list_page.dart
    memory_detail_page.dart
    memory_form_page.dart
    calendar_page.dart
    settings_page.dart
    account_page.dart
  providers/
    providers.dart                 # Riverpod 状态和业务操作
  services/
    notification_service.dart
    photo_service.dart
    location_service.dart
  theme/
    app_theme.dart
  utils/
    lunar_utils.dart
    place_dedup.dart               # 地点重复检测与合并
    relationship_insights.dart     # 关系维护状态计算
    backup_preview.dart            # 备份导入预览与校验
  widgets/
```

## 验证

提交前建议运行：

```bash
flutter analyze
flutter test
```

当前测试覆盖：

- 人物、地点、回忆和状态模型序列化。
- 照片服务基础行为。
- 应用 smoke test。
- 地点重复检测、地点合并和回忆引用重定向。
- 关系维护状态、首页关注优先级和备份导入预览。

## 后续开发方向

- 开发阶段继续保留通用 APK，优先覆盖更多 Android 设备。
- 第一代产品稳定后，上架前改用 AAB / ABI 分包降低安装体积。
- 继续加强关系维护、回忆回顾、备份可靠性和真机兼容性测试。

## 数据与隐私

- 数据默认保存在本地设备。
- Android/iOS 使用 Drift + SQLite。
- Web 预览使用 SharedPreferences 状态镜像。
- 导出备份为 JSON，包含人物、地点、回忆、设置、提醒配置和地点合并历史。
- 本项目不要求登录账号，也不默认上传数据。

## 应用标识

- Android 包名：`com.cnxin.lifelog.v2`
- iOS Bundle ID：`com.cnxin.lifelog.v2`
- 显示名称：`LifeLog v2`

v2 使用独立应用标识，可与原版 LifeLog 同时安装。

## 文档

- [DEVELOPMENT.md](DEVELOPMENT.md) - 开发环境配置
- [DEPLOYMENT.md](DEPLOYMENT.md) - Web/Android/iOS 部署
- [REMINDERS.md](REMINDERS.md) - 智能提醒说明
- [PREFERENCES.md](PREFERENCES.md) - 人物喜好与禁忌
- [SQLITE_MIGRATION.md](SQLITE_MIGRATION.md) - SQLite 迁移说明
- [ICON_SPLASH_SETUP.md](ICON_SPLASH_SETUP.md) - 图标和启动页
- [CHANGELOG.md](CHANGELOG.md) - 变更记录

## 当前版本

`pubspec.yaml`:

```yaml
version: 0.3.1+45
```

## License

MIT License
