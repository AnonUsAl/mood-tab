# mood-tab

mood-tab 是一款专注于治愈与陪伴的跨平台个人情绪记录软件。在隐私安全方面，moodtab 采用高性能本地数据库存储，100% 不上传云端，给你的内心世界最安全的物理保护。

## 功能特性

- **情绪记录**：10 种情绪类型（开心、平静、感恩、兴奋、一般、疲惫、难过、焦虑、愤怒、孤独），5 级强度调节，16 个预设触发标签，自由文字备注
- **今日概览**：首页展示当日情绪记录，智能时段问候，快速记录入口
- **时间线历史**：按日期分组展示所有记录，左滑删除，点击查看详情
- **统计分析**：周/月维度切换，情绪强度趋势折线图，情绪类型分布条形图，本期概况汇总
- **隐私优先**：所有数据通过 SQLite 存储在设备本地，绝不上传云端
- **治愈系 UI**：柔和配色、圆角卡片、温和过渡动画

## 技术栈

| 模块 | 技术 |
|------|------|
| 框架 | Flutter (Dart) |
| 状态管理 | Provider |
| 本地数据库 | sqflite + path_provider |
| 图表 | fl_chart |

## 项目结构

```
lib/
├── main.dart                      # 应用入口 + 底部导航框架
├── models/
│   ├── mood_type.dart             # 情绪类型枚举（颜色、emoji、标签）
│   ├── mood_record.dart           # 情绪记录数据模型
│   └── mood_tag.dart              # 触发标签预设
├── services/
│   └── database_service.dart      # SQLite 数据库服务（CRUD）
├── providers/
│   └── mood_provider.dart         # 全局状态管理
├── pages/
│   ├── home_page.dart             # 首页 - 今日概览
│   ├── mood_record_page.dart       # 情绪记录页
│   ├── history_page.dart          # 历史记录页 - 时间线
│   └── stats_page.dart            # 统计分析页
├── theme/
│   └── app_theme.dart             # 治愈系主题配置
└── widgets/
    ├── intensity_dots.dart        # 情绪强度圆点组件
    └── empty_state.dart           # 空状态占位组件
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.5.0
- Dart SDK >= 3.5.0
- Android Studio / Xcode（如需运行模拟器）

### 运行步骤

```bash
# 1. 克隆仓库
git clone https://github.com/yourname/mood-tab.git
cd mood-tab

# 2. 补全平台文件（首次需要）
flutter create .

# 3. 安装依赖
flutter pub get

# 4. 运行
flutter run
```

> **说明**：仓库中只包含 `lib/` 源码和 `pubspec.yaml`，平台相关文件（android/ios/macos/windows/linux）需通过 `flutter create .` 自动生成。

### 构建发布

```bash
# Android
flutter build apk

# iOS
flutter build ios

# macOS
flutter build macos
```

## 隐私声明

mood-tab 不收集、不上传、不分享任何用户数据。所有情绪记录仅存储在用户设备的本地 SQLite 数据库中。卸载应用后数据将自动清除。

## License

MIT
