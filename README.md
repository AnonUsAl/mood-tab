# mood-tab

mood-tab 是一款专注于治愈与陪伴的跨平台个人情绪记录软件。在隐私安全方面，mood-tab 采用高性能本地数据库存储，100% 不上传云端，给你的内心世界最安全的物理保护。

## 功能特性

### 核心功能

- **情绪记录**：10 种情绪类型（开心、平静、感恩、兴奋、一般、疲惫、难过、焦虑、愤怒、孤独），5 级强度调节，16 个预设触发标签 + 自定义标签，自由文字备注
- **情绪日记**：每条记录可附加长篇日记，记录更深层的感受与思考
- **今日概览**：首页展示当日情绪记录，智能时段问候，快速记录入口
- **日历视图**：月历展示每日情绪记录情况，点击日期查看当日详情
- **时间线历史**：按日期分组展示所有记录，左滑删除，点击查看详情
- **统计分析**：周/月维度切换，情绪强度趋势折线图，情绪类型分布条形图，触发标签排行，时段情绪分析，星期情绪分析，环比对比，本期概况汇总
- **情绪波动预警**：自动分析近期情绪波动幅度，给出贴心提醒
- **标签管理**：支持自定义情绪触发标签，可选择 emoji 图标，预设标签不可修改

### 心理测评

- **专业量表**：内置接入 [云术心理测量平台](https://pt.cldery.com/)，提供 PHQ-9、GAD-7、SDS、SAS 等专业心理测评量表
- **WebView 套壳**：测评页面直接加载云端网页，无需 app 内更新即可同步最新量表

### 个性化与隐私

- **每日提醒**：可自定义时间的情绪记录提醒推送
- **连续打卡**：记录连续记录天数，培养情绪觉察习惯
- **隐私锁**：PIN 码保护，防止他人查看情绪记录
- **主题切换**：浅色 / 深色模式自由切换，全页面 context 感知颜色自适应
- **数据导出**：支持 CSV 表格、PDF 报告导出，JSON 备份与恢复
- **隐私优先**：所有情绪数据通过 SQLite 存储在设备本地，绝不上传云端

### 关于

- **治愈系 UI**：柔和配色、圆角卡片、温和过渡动画
- **100% 本地存储**：情绪记录不上云，心理测评通过 WebView 加载

## 技术栈

| 模块 | 技术 |
|------|------|
| 框架 | Flutter (Dart) |
| 状态管理 | Provider |
| 本地数据库 | sqflite + path_provider |
| 图表 | fl_chart |
| WebView | webview_flutter |
| 本地通知 | flutter_local_notifications + timezone |
| 数据导出 | pdf + share_plus |
| 偏好存储 | shared_preferences |

## 项目结构

```
lib/
├── main.dart                          # 应用入口 + 底部导航框架
├── models/
│   ├── mood_type.dart                 # 情绪类型枚举（颜色、emoji、标签）
│   ├── mood_record.dart               # 情绪记录数据模型
│   └── mood_tag.dart                  # 触发标签预设
├── services/
│   ├── database_service.dart          # SQLite 数据库服务（CRUD）
│   ├── preferences_service.dart       # 偏好设置存储服务
│   ├── notification_service.dart      # 本地通知服务
│   └── mood_analysis_service.dart     # 情绪波动分析服务
├── providers/
│   └── mood_provider.dart             # 全局状态管理
├── pages/
│   ├── home_page.dart                 # 首页 - 今日概览
│   ├── mood_record_page.dart          # 情绪记录页
│   ├── diary_page.dart                # 情绪日记页
│   ├── calendar_page.dart             # 日历视图页
│   ├── history_page.dart              # 历史记录页 - 时间线
│   ├── stats_page.dart                # 统计分析页（趋势/分布/标签/时段/星期/环比）
│   ├── settings_page.dart             # 设置页（我的）
│   ├── tag_management_page.dart       # 标签管理页（自定义标签增删）
│   ├── splash_page.dart               # 启动加载页（暖心语句）
│   ├── crisis_support_page.dart       # 危机支持页（心理热线）
│   ├── assessment_web_page.dart       # 心理测评页（WebView 套壳）
│   └── about_page.dart                # 关于作者页
├── theme/
│   └── app_theme.dart                 # 治愈系主题配置
└── widgets/
    ├── intensity_dots.dart            # 情绪强度圆点组件
    └── empty_state.dart               # 空状态占位组件
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.5.0
- Dart SDK >= 3.5.0
- Android Studio / Xcode（如需运行模拟器）

### 运行步骤

```bash
# 1. 克隆仓库
git clone https://github.com/AnonUsAl/mood-tab.git
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

mood-tab 不收集、不上传、不分享任何用户数据。所有情绪记录仅存储在用户设备的本地 SQLite 数据库中。心理测评功能通过 WebView 加载 [pt.cldery.com](https://pt.cldery.com/)，测评数据由该平台处理，不存储在 app 本地。卸载应用后本地数据将自动清除。

## 关于作者

- **作者**：anonusal
- **GitHub**：[AnonUsAl](https://github.com/AnonUsAl)
- **团队**：[云术工作室 ClouderyStudio](https://github.com/ClouderyStudio)
- **心理测量平台**：[pt.cldery.com](https://pt.cldery.com/)

## License

MIT
