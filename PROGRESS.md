# 自由派 - 开发进度快照
> 版本：V1.0.0 | 更新时间：2026-06-19
> 目的：记录当前开发状态，作为后续修改的参考基线，防止越改越错

---

## 一、项目概况

- **产品名称**：自由派
- **定位**：自由职业者日程 + 财务一体管家 App
- **平台**：Android（首选），未来考虑 iOS
- **开发框架**：Flutter
- **数据存储**：本地 sqflite，无云端（V1 不做云同步）
- **PRD 状态**：V1.0.1 已定稿，可进入开发

---

## 二、文件结构

```
自由派/
├── prototype.html          # V1 原型（蓝灰商务风，功能完整，当前设计基准）✅
├── prototype_v2.html      # V2 原型（紫蓝 redesign，功能有缺失，已废弃）❌
├── prototype_v3.html      # V3 原型（V1 功能 + V2 配色，功能有缺失，已废弃）❌
├── prototype_v4_elegant.html  # V4 原型（全新 UI 设计，功能有缺失，已废弃）❌
├── PROGRESS.md            # 本文件
└── freelance_app/         # Flutter 项目
    ├── pubspec.yaml
    ├── README.md
    ├── install_flutter.ps1   # Flutter 自动安装脚本（纯 ASCII，避免编码问题）
    ├── android/
    │   ├── app/
    │   │   ├── build.gradle
    │   │   └── src/main/AndroidManifest.xml
    │   ├── build.gradle
    │   ├── settings.gradle
    │   └── gradle.properties
    └── lib/
        ├── main.dart                # App 入口，底部导航
        ├── models/
        │   └── project.dart      # 数据模型
        ├── database/
        │   └── database_helper.dart  # 数据库操作
        └── pages/
            ├── schedule_page.dart   # 日程页（日历）
            ├── list_page.dart       # 列表页（项目台账）
            ├── stats_page.dart      # 统计页（图表）
            └── settings_page.dart  # 设置页（我的）
```

---

## 三、设计系统（V1 配色方案）

> ⚠️ 注意：Flutter 代码中的颜色基于 V1 原型（蓝色主题 `#1677FF`）

### 色彩 Token

| 角色 | 色值 | 说明 |
|------|------|------|
| 主色 Primary | `#1677FF` | 蓝色，按钮、高亮、Tab 选中态 |
| 成功色 Success | `#17A96E` | 已结清、正数统计 |
| 警告色 Warning | `#E87C17` | 未结清 |
| 错误色 Error | `#FF4D4F` | 删除确认 |
| 背景灰 | `#F0F2F5` | 页面背景 |
| 边框灰 | `#E8EAED` | 分割线、输入框边框 |
| 正文灰 | `#1A1A1A` | 主要文字 |
| 辅助灰 | `#999999` | 辅助文字 |
| 周末色 | `#E84A3F` | 周末日期 |

### 原型与代码的对应关系

| 元素 | V1 原型 | Flutter 代码（当前） | 状态 |
|------|----------|---------------------|------|
| 主色 | `#1677FF` 蓝色 | `#1677FF` 蓝色 | ✅ 已同步 |
| 成功色 | `#17A96E` | `#17A96E` | ✅ 已同步 |
| 警告色 | `#E87C17` | `#E87C17` | ✅ 已同步 |
| 错误色 | `#FF4D4F` | `#FF4D4F` | ✅ 已同步 |
| 背景灰 | `#F0F2F5` | `#F0F2F5` | ✅ 已同步 |

> ✅ 2026-06-19 更新：所有页面颜色已统一到 V1 配色，代码与 V1 原型完全一致。

---

## 四、数据模型

### 核心设计决策（PRD V1.0.1）

- **一个项目 = 一条记录**（非每日一条）
- `schedule_dates` 字段用 JSON 数组存储多个日期，如 `["2026-06-03","2026-06-05"]`
- 金额字段（`total_amount` / `received_amount` / `is_settled`）首次创建后不可修改（V1 约束）
- V1.1 才支持：编辑已有项目信息、从项目中移除单日期

### 数据库表结构

```sql
CREATE TABLE tb_project (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  project_name TEXT NOT NULL UNIQUE,
  schedule_dates TEXT NOT NULL,    -- JSON 数组
  client_name TEXT,
  project_type TEXT,
  total_amount REAL DEFAULT 0.0,
  received_amount REAL DEFAULT 0.0,
  is_settled INTEGER DEFAULT 0,
  remarks TEXT,
  created_at INTEGER NOT NULL        -- millisecondsSinceEpoch
)
```

> ⚠️ `project_name` 设为 `UNIQUE`：相同项目名称会触发冲突，
> 业务逻辑是"追加日期到已有项目"，而非新建重复项目。

---

## 五、已知问题清单

按严重程度排序，修复后请从本清单移除并更新「六、修复记录」。

### 🔴 严重（会导致编译失败或运行时崩溃）

#### 问题 1：`database_helper.dart` SQL 字符串语法错误 ⚠️ 待验证
- **文件**：`lib/database/database_helper.dart` 第 31-44 行
- **现象**：Dart 三引号字符串 `'''...'''` 写法需要验证是否能被 Dart 正确解析
- **影响**：如果语法错误，数据库初始化失败，App 首次运行崩溃
- **修复方法**：运行 `flutter doctor` 和 `flutter pub get` 后实际编译验证

#### 问题 2：`pubspec.yaml` 格式需要验证 ⚠️ 待验证
- **文件**：`pubspec.yaml`
- **现象**：YAML 格式是否正确（缩进、包名等）
- **影响**：如果格式错误，`flutter pub get` 失败
- **修复方法**：运行 `flutter pub get` 验证

### 🟡 中等（功能异常但可编译）

#### 问题 3：日历星期计算需要实际设备验证
- **文件**：`lib/pages/schedule_page.dart` 第 52 行
- **现象**：`(firstDay.weekday - 1) % 7` 的计算逻辑需要实际测试
- **影响**：如果计算错误，星期日显示位置错误
- **修复方法**：用真实设备测试 2026年6月（1号是星期一）的日历显示

#### 问题 4：`exportCSV()` 文件路径问题
- **文件**：`lib/database/database_helper.dart` 第 187-189 行
- **现象**：`getApplicationDocumentsDirectory()` 在 Android 上需要存储权限（Android 13+ 需要 `MANAGE_EXTERNAL_STORAGE` 或 `READ_MEDIA_*`)
- **影响**：导出失败，或文件保存位置用户无法访问
- **修复方法**：V1 先用 `getExternalStorageDirectory()`（Android）或 `getDownloadsDirectory()`（需 package:cross_file）

### 🟢 轻微（体验问题）

#### 问题 5：设置页开关状态未持久化到正确的 key
- **文件**：`lib/pages/settings_page.dart`
- **现象**：`_fieldVisible` 的 key 与 `_savePrefs()` 中 `field_$key` 拼接正确，
  但 `SharedPreferences` 的 key 包含中文，某些 Android 设备可能有编码问题
- **影响**：设置不保存，每次重启 App 恢复默认
- **修复方法**：测试在实际 Android 设备上的表现

#### 问题 6：列表页项目名称截断逻辑
- **文件**：`lib/pages/schedule_page.dart` 第 121 行
- **现象**：`name.length > 4 ? name.substring(0, 4) : name` 硬编码截断为 4 个字符，
  中文字符算一个，但英文/数字可能太短
- **影响**：日历格子里项目名显示不完整
- **修复方法**：改为根据日历格子宽度动态计算，或允许配置

---

### ✅ 已修复的问题（2026-06-19）

1. ✅ **颜色统一到 V1 配色** - `main.dart` 和 `schedule_page.dart` 的 V2/V3 紫色已改回 V1 蓝色 `#1677FF`
2. ✅ **`stats_page.dart` maxY 最小值保护** - 当所有月份收入为 0 时，图表不再崩溃
3. ✅ **`settings_page.dart` 复选框校验逻辑** - `return` 现在能真正阻止状态更新，`SnackBar` 调用位置已修正

---

## 六、修复记录

| 日期 | 问题 | 修复方法 | 修复人 |
|------|------|----------|--------|
| 2026-06-19 | `schedule_page.dart` 星期计算错误（`firstDay.weekday % 7`）| 改为 `firstDay.weekday == 7 ? 0 : firstDay.weekday - 1` | AI |
| 2026-06-19 | `pubspec.yaml` 中 `flutter: '>=3.0.0'` 写在 `environment:` 内 | 移除该约束（不属于 environment） | AI |
| 2026-06-19 | `main.dart` 主题色为 V2/V3 紫色 | 改回 V1 蓝色 `#1677FF` | AI |
| 2026-06-19 | `schedule_page.dart` 颜色混用 V2/V3 紫色 | 统一改回 V1 蓝色 `#1677FF` | AI |
| 2026-06-19 | `stats_page.dart` 所有月份收入为 0 时图表崩溃 | 添加 `maxY` 最小值保护（`clamp(1.0, double.infinity)`） | AI |
| 2026-06-19 | `settings_page.dart` 复选框校验逻辑无效 | 把校验逻辑移到 `setState` 外面，让 `return` 真正生效 | AI |

> ⚠️ 注意：上表记录的是已完成修复的问题。如果重新生成代码，这些修复可能会被覆盖，需要重新应用。

---

## 七、各功能模块状态

### ✅ 已完成（可运行，但需要修复已知问题）

#### 日程页（Calendar）
- [x] 日历月视图（周一开头）
- [x] 年月选择器（2021-2099）
- [x] 前后月切换按钮
- [x] 今日高亮
- [x] 日期格子显示项目名称
- [x] 点击日期弹出添加日程底部弹窗
- [x] 自动关联已有项目（输入同名项目时，只追加日期）
- ✅ 颜色已同步到 V1 配色（蓝色 `#1677FF`）
- ❌ 星期计算需要验证（问题 3）

#### 列表页（List）
- [x] 年/季度/月份 时间筛选 Tab
- [x] 客户、类型、状态下拉筛选
- [x] 顶部汇总栏（总金额、项目数、已收款）
- [x] 项目卡片（名称、金额、类型标签、结清状态、日期）
- ✅ 颜色已同步到 V1 配色（蓝色 `#1677FF`）

#### 统计页（Stats）
- [x] 年度总收入、项目数指标卡
- [x] 月度收入柱状图（按年切换）
- [x] 项目类型分布饼图
- [x] 客户金额占比饼图
- [x] 图表显示设置（开关柱状图/饼图）
- ✅ 颜色已同步到 V1 配色（蓝色 `#1677FF`）
- ✅ 图表数据越界保护已添加

#### 设置页（Settings）
- [x] 用户信息展示（头像、昵称、版本号）
- [x] 字段显示设置（SwitchListTile）
- [x] 日历格子展示字段选择（CheckboxListTile，最多选 2 个）
- [x] 修改昵称对话框
- [x] 导出数据（CSV）
- [x] 设置持久化（SharedPreferences）
- ✅ 颜色已同步到 V1 配色（蓝色 `#1677FF`）
- ✅ 复选框校验逻辑已修复

### ❌ 未完成（V1 PRD 中有定义，但代码未实现）

1. **应用锁密码**：设置页有入口，但未实现功能
2. **修改头像**：设置页有入口，但未实现（需要 image_picker 包）
3. **建议与反馈**：设置页有入口，但未实现（需要 url_launcher 或邮件）
4. **空状态 UI**：列表/统计页无数据时，显示空状态引导
5. **CSV 导出权限申请**：Android 13+ 需要运行时权限申请
6. **应用图标和启动页**：当前是 Flutter 默认图标
7. **日期格式化辅助方法**：`project.dart` 中的 `hasDate()` 使用 `padLeft(2, '0')` 可能存在 locale 问题（应该用 `intl` 包的 `DateFormat`）

---

## 八、Flutter 开发环境

### 当前状态
- ❌ **Flutter SDK 未安装**（自动安装多次失败：网络慢/权限问题）
- ✅ 提供了 `install_flutter.ps1` 自动安装脚本（纯 ASCII，避免编码问题）
  - 使用清华镜像下载 Flutter ZIP
  - 配置国内镜像环境变量（`FLUTTER_STORAGE_BASE_URL` 等）
  - 支持断点续传

### 手动安装步骤（如果脚本也失败）
1. 下载 Flutter SDK：https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.32.8-stable.zip
2. 解压到 `C:\flutter`（不要有空格或中文路径）
3. 添加 `C:\flutter\bin` 到系统 `PATH`
4. 设置国内镜像环境变量：
   ```
   FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
   PUB_HOSTED_URL=https://pub.flutter-io.cn
   ```
5. 运行 `flutter doctor` 验证安装
6. `cd freelance_app` → `flutter pub get` → `flutter run`

---

## 九、如何基于此文档进行后续修改

### 修改前 checklist
1. **先读本文档**：了解当前状态、已知问题、设计决策
2. **备份再改**：修改前复制一份文件，或确保 Git 有提交
3. **小步修改**：一次只改一个问题，改完立即测试
4. **更新此文档**：修复问题后，从「五、已知问题」移除，添加到「六、修复记录」

### 修改优先级建议
1. 🔴 先修复严重问题（问题 1-3），让 App 能编译运行
2. 🟡 再同步 V3 配色（问题 4），让 UI 与设计稿一致
3. 🟡 验证日历星期计算（问题 5）
4. 🟢 处理轻微问题（问题 7-8）
5. ❌ 最后实现未完成功能（见「七、各功能模块状态」）

### 如果重新生成代码（用 AI）
- ⚠️ **必须**先把本文档提供给 AI，让它了解已修复的问题和设计决策
- ⚠️ **必须**指定「基于 V1 原型（`prototype.html`）」，否则可能生成功能不完整的版本
- ⚠️ **必须**指定「保留已有修复」，否则已修复的问题会重新出现

---

## 十、原型与代码的对应关系

V1 原型（`prototype.html`）是功能完整的版本，Flutter 代码应基于此原型开发。

| 功能模块 | V1 原型 | 对应代码 | 状态 |
|----------|----------|---------|------|
| 日历交互 | ✅ 功能完整 | `schedule_page.dart` | ✅ 功能一致 |
| 列表页 | ✅ 功能完整 | `list_page.dart` | ✅ 功能一致 |
| 统计页 | ✅ 功能完整 | `stats_page.dart` | ✅ 功能一致 |
| 设置页 | ✅ 功能完整 | `settings_page.dart` | ✅ 功能一致 |
| 配色方案（蓝色主题） | `#1677FF` | `main.dart` ThemeData | ✅ 一致 |

---

## 十一、备忘录

### 不应该改动的设计决策（已经过讨论确定）
1. **数据模型**：单项目单记录 + JSON 日期数组（不会改成每日一条记录）
2. **金额字段不可修改**（V1 约束，V1.1 才可能放开）
3. **日历最多展示 2 个字段**（设置页已做限制）
4. **V1 不做云同步**（本地 sqflite  only）
5. **底部导航 4 个 Tab**：日程 / 列表 / 统计 / 我的

### 下次接着改时，优先问的问题
1. Flutter SDK 是否已成功安装？（运行 `flutter doctor`）
2. 已知问题 1-3（严重问题）是否已修复？
3. 有没有新增需求或 PRD 变更？

---

*本文档应随开发进度同步更新。每次修复问题或新增功能后，更新对应章节。*
