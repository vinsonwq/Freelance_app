# 自由派（freelance_app）—— 完整功能复刻文档

> **版本**：V1.0.0（对应 Flutter 代码当前状态）  
> **更新日期**：2026-06-24  
> **用途**：供其他程序员完整复刻现有功能  
> **设计基准原型**：`prototype.html`（V1 原型，蓝灰商务风）

---

## 一、产品概述

| 项目 | 内容 |
|------|------|
| 产品名称 | 自由派 |
| 定位 | 自由职业者日程 + 财务一体管家 App |
| 目标用户 | 自由职业者、独立设计师、兼职人员 |
| 核心价值 | 一个 App 管理项目日程和收入财务，数据本地存储 |
| 技术栈 | Flutter 3.44.2 (Dart) + SQLite + SharedPreferences |
| 当前平台 | Android（已编译通过，可运行） |
| 包名 | `com.freelanceapp.freelance_app` |

### 设计规范
- 仅支持**竖屏**
- Material 3 设计语言
- 主题色：`#1677FF`（蓝色）
- 底部导航 4 个 Tab：**日程 / 列表 / 统计 / 我的**

---

## 二、开发环境要求

### 必装软件
| 软件 | 版本/说明 |
|------|----------|
| Flutter SDK | >=3.0.0 <4.0.0（实测用 v3.44.2） |
| Dart SDK | 随 Flutter 附带（>=3.12.0） |
| Android SDK | v36.1.0（含 platform-tools, build-tools, cmdline-tools） |
| Android Studio | 最新版（用于 SDK 管理和调试，非必需但推荐） |
| Java/Kotlin | JDK 17（Gradle 编译需要） |

### 国内镜像配置（必须）
环境变量中添加：
```
FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
PUB_HOSTED_URL=https://pub.flutter-io.cn
```

Android 构建使用阿里云 Maven 镜像（已配置在 `android/build.gradle.kts` 和 `android/settings.gradle.kts` 中）。

Gradle 使用腾讯云镜像（已配置在 `android/gradle/wrapper/gradle-wrapper.properties` 中）。

### 创建项目命令
```bash
flutter create --org com.freelanceapp --project-name freelance_app .
```
或手动按以下目录结构创建：

---

## 三、项目目录结构

```
freelance_app/
├── pubspec.yaml                    # 项目配置 & 依赖声明
├── pubspec.lock                    # 依赖版本锁文件（自动生成）
├── analysis_options.yaml           # Dart 代码分析规则
├── README.md                       # 运行说明
│
├── lib/
│   ├── main.dart                   # 应用入口 + MaterialApp + 底部导航框架
│   ├── models/
│   │   └── project.dart            # Project 数据模型（SQLite ↔ Dart 映射）
│   ├── database/
│   │   └── database_helper.dart    # 单例数据库管理器（CRUD + 查询 + 导出）
│   └── pages/
│       ├── schedule_page.dart      # 日程页（日历月视图 + 添加日程弹窗）
│       ├── list_page.dart          # 列表页（项目管理 + 筛选）
│       ├── stats_page.dart         # 统计页（柱状图 + 饼图）
│       └── settings_page.dart      # 设置页（字段开关 + 数据导出）
│
├── android/
│   ├── app/
│   │   ├── build.gradle.kts        # App 构建配置
│   │   └── src/main/
│   │       ├── AndroidManifest.xml # App 清单文件
│   │       └── kotlin/com/freelanceapp/freelance_app/
│   │           └── MainActivity.kt # Activity 入口
│   ├── build.gradle.kts            # 项目级构建配置（阿里云 Maven 镜像）
│   ├── settings.gradle.kts         # Gradle 设置（插件 + 子模块）
│   ├── gradle.properties           # JVM 内存参数
│   └── gradle/wrapper/
│       └── gradle-wrapper.properties # Gradle 版本（9.1.0 腾讯云镜像）
│
├── test/
│   └── widget_test.dart            # 默认测试文件
│
└── build/                          # 编译输出（gitignore）
```

---

## 四、依赖包清单

### `pubspec.yaml` 完整内容

```yaml
name: freelance_app
description: 自由派 - 自由职业者日程与财务管家
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0          # SQLite 本地数据库
  path_provider: ^2.1.0     # 获取应用文档目录路径
  intl: ^0.19.0             # 日期格式化
  fl_chart: ^0.68.0         # 柱状图 + 饼图
  shared_preferences: ^2.2.0 # 键值对设置持久化

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0     # 代码风格检查

flutter:
  uses-material-design: true
```

### 实际解析版本（pubspec.lock）

| 包名 | 实际版本 | 用途 |
|------|---------|------|
| sqflite | 2.4.3 | 本地 SQLite 数据库操作 |
| sqflite_android | 2.4.3 | Android 平台 SQLite 实现 |
| sqflite_common | 2.5.11 | 平台通用接口 |
| path_provider | 2.1.6 | 获取文件系统路径 |
| intl | 0.19.0 | 国际化日期格式 |
| fl_chart | 0.68.0 | BarChart 柱状图 + PieChart 饼图 |
| shared_preferences | 2.5.5 | 设置持久化存储 |

---

## 五、数据模型（核心）

### 5.1 数据库表结构

**单表设计**：所有数据存储在 `tb_project` 表中。

```sql
CREATE TABLE tb_project (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,  -- 自增主键
  project_name    TEXT NOT NULL UNIQUE,                -- 项目名称（唯一约束）
  schedule_dates  TEXT NOT NULL,                        -- JSON 数组：["2026-06-01", "2026-06-15"]
  client_name     TEXT,                                 -- 客户名称
  project_type    TEXT,                                 -- 项目类型
  total_amount    REAL DEFAULT 0.0,                     -- 项目总额（首次创建后不可修改）
  received_amount REAL DEFAULT 0.0,                     -- 已收金额
  is_settled      INTEGER DEFAULT 0,                   -- 是否结清（0=否 1=是）
  remarks         TEXT,                                 -- 备注
  created_at      INTEGER NOT NULL                      -- 创建时间戳（毫秒）
);
```

### 5.2 核心设计决策

1. **一个项目 = 一条记录**，一个项目可以关联多个工作日期
2. 多个日期以 **JSON 数组字符串** 存储在 `schedule_dates` 字段
3. `project_name` 有 **UNIQUE 约束**，同名项目视为同一项目
4. **金额字段（total_amount / received_amount / is_settled）首次创建后不可修改**（这是 V1 的业务规则，UI 上不提供编辑入口）
5. 日期格式统一为 `"YYYY-MM-DD"`

### 5.3 Dart 数据模型 (`lib/models/project.dart`)

```dart
import 'dart:convert';
import 'package:flutter/material.dart';

class Project {
  int? id;
  String projectName;           // 项目名称
  List<String> scheduleDates;   // 工作日期列表 ["YYYY-MM-DD", ...]
  String? clientName;           // 客户名称
  String? projectType;          // 项目类型
  double totalAmount;           // 总额
  double receivedAmount;        // 已收金额
  bool isSettled;               // 是否结清
  String? remarks;              // 备注
  int createdAt;                // 创建时间戳（毫秒）

  Project({
    this.id,
    required this.projectName,
    required this.scheduleDates,
    this.clientName,
    this.projectType,
    this.totalAmount = 0.0,
    this.receivedAmount = 0.0,
    this.isSettled = false,
    this.remarks,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  // 序列化：Dart 对象 → Map（存入 SQLite）
  Map<String, dynamic> toMap() { ... }

  // 反序列化：Map → Dart 对象（从 SQLite 读取）
  factory Project.fromMap(Map<String, dynamic> map) { ... }

  // 辅助方法：判断该项目是否在某年某月有工作日
  bool hasDate(int year, int month) { ... }

  // 辅助方法：判断该项目是否在某年有工作日
  bool hasDateInYear(int year) { ... }
}
```

**关键字段映射关系：**

| 数据库字段 | Dart 属性 | 类型 | 说明 |
|-----------|----------|------|------|
| id | id | int? | 主键 |
| project_name | projectName | String | 唯一约束 |
| schedule_dates | scheduleDates | List\<String\> | JSON 编码/解码 |
| client_name | clientName | String? | 可空 |
| project_type | projectType | String? | 可空 |
| total_amount | totalAmount | double | 默认 0.0 |
| received_amount | receivedAmount | double | 默认 0.0 |
| is_settled | isSettled | bool | 0→false, 1→true |
| remarks | remarks | String? | 可空 |
| created_at | createdAt | int | 毫秒时间戳 |

---

## 六、数据库操作层 (`lib/database/database_helper.dart`)

### 6.1 架构模式
- **单例模式**：`static final DatabaseHelper instance = DatabaseHelper._init()`
- 延迟初始化：首次调用 `database` getter 时创建数据库
- 数据库文件路径：`getApplicationDocumentsDirectory()/freelance.db`

### 6.2 完整 API 方法清单

#### CRUD 操作

| 方法签名 | 功能 | 说明 |
|---------|------|------|
| `Future<int> createProject(Project p)` | 创建新项目 | 插入一条记录，返回新 ID |
| `Future<Project?> getProjectByName(String name)` | 按名称查询 | 用于检测重复项目 |
| `Future<int> deleteProject(int id)` | 删除项目 | 按 ID 删除 |
| `Future<int> appendDates(String name, List<String> dates)` | 追加日期 | 给已有项目追加工作日期 |

#### 查询操作

| 方法签名 | 功能 | 返回值 |
|---------|------|--------|
| `Future<List<Project>> getAllProjects()` | 获取全部项目 | 全量列表 |
| `Future<List<Project>> getProjectsByYear(int year)` | 按年查询 | 该年有日期的项目 |
| `Future<List<Project>> getProjectsByMonth(int year, int month)` | 按年月查询 | 该月有日期的项目 |
| `Future<List<Project>> getProjectsByQuarter(int year, int quarter)` | 按季度查询 | Q1=1~3月, Q2=4~6... |
| `Future<List<Project>> getProjectsByDate(DateTime date)` | 按天查询 | 当天有日程的项目 |

#### 辅助查询

| 方法签名 | 功能 |
|---------|------|
| `Future<List<String>> getAllProjectNames()` | 所有项目名称列表（用于下拉选择/去重提示） |
| `Future<List<String>> getAllClientNames()` | 所有客户名称列表 |
| `Future<List<String>> getAllProjectTypes()` | 所有项目类型列表 |

#### 统计分析

| 方法签名 | 功能 |
|---------|------|
| `Future<double> getYearTotal(int year)` | 某年所有项目总金额 |
| `Future<double> getYearReceived(int year)` | 某年已收金额合计 |
| `Future<int> getYearProjectCount(int year)` | 某年项目总数 |

#### 数据导出

| 方法签名 | 功能 |
|---------|------|
| `Future<String> exportCSV()` | 导出全部数据为 CSV 文件，返回文件路径 |

---

## 七、页面功能详细规格

### 7.1 应用入口 (`lib/main.dart`)

**功能清单：**
- [x] 强制竖屏锁定（`DeviceOrientation.portraitUp`）
- [x] MaterialApp 配置：标题"自由派"、关闭 Debug 标签
- [x] 主题配置：
  - 主色 `#1677FF`
  - AppBar 白底黑字、无阴影、左对齐标题
  - Material 3 启用
- [x] HomePage StatefulWidget：管理底部导航状态
- [x] BottomNavigationBar（固定类型）：
  - 4 个 Tab：日程 / 列表 / 统计 / 我的
  - 选中蓝色 `#1677FF`，未选灰色 `#999999`
  - 字号 11px
  - 图标区分 outlined 和 filled 态

### 7.2 日程页 (`lib/pages/schedule_page.dart`)

**页面组成（从上到下）：**

#### ① 年月筛选栏（Row）
- 左箭头按钮 → 切换到上个月
- 年月文字 "YYYY年MM月" → 点击弹出滚轮选择器
  - 年份范围：2021 ~ 2099
  - 月份：1 ~ 12
- 右箭头按钮 → 切换到下个月

#### ② 星期栏（GridView 单行 7 列）
- 固定显示：一 二 三 四 五 六 日

#### ③ 日历网格（GridView 7 列，约 6 行）
- **当月日期格子**：
  - 白色背景，黑色日期数字（`#1A1A1A`）
  - 如果当天有项目 → 格子底部显示项目信息
  - 最多展示 **2 个字段**（可配置，默认显示项目名称和项目类型）
  - 项目名称截断为前 4 个字符
  - 有项目的格子背景色：主色浅蓝 `Color(0xFF1677FF).withOpacity(0.08)`
  - 今日高亮：主色蓝背景 `#1677FF` + 白色文字
  - 周末日期数字：红色 `#E84A3F`
  
- **非当月日期**：灰色文字 `#BBBBBB`，不可点击

- **点击日期**：打开 `_AddProjectSheet`（BottomSheet 弹窗）

#### ④ 右上角浮动按钮 (+)
- 点击直接打开新建弹窗，默认选中今天

#### ⑤ 新建/添加日程弹窗 (_AddProjectSheet)
- **BottomSheet 形式**，圆角顶部
- **表单字段**：

  | 字段 | 控件类型 | 必填 | 默认值 | 说明 |
  |------|---------|------|--------|------|
  | 项目名称 | TextField | ✅ 是 | 空 | 第一行自动获焦 |
  | 客户名称 | TextField | 否 | 空 | — |
  | 项目类型 | TextField | 否 | 空 | — |
  | 项目总额 | TextField(数字键盘) | 否 | 0.0 | 首次创建后不可改 |
  | 已收金额 | TextField(数字键盘) | 否 | 0.0 | — |
  | 结清状态 | Switch | 否 | 关 | 开=已结清 |
  | 备注 | TextField(多行) | 否 | 空 | 最大 3 行 |

- **核心业务逻辑**：
  1. 用户输入项目名称后，自动调用 `getProjectByName()` 检查是否已存在
  2. **如果项目已存在**：只追加该日期到已有项目的 `scheduleDates`（调用 `appendDates()`）
  3. **如果项目不存在**：创建新项目（调用 `createProject()`），`scheduleDates` 只包含当前点击的日期
  4. 保存成功后关闭弹窗并刷新日历
  5. 表单验证：项目名称不能为空

#### ⑥ 日历星期计算逻辑
```dart
// 获取当月第一天的星期偏移量（周一 = 0）
final firstDay = DateTime(year, month, 1);
final startWeekday = firstDay.weekday == 7 ? 0 : firstDay.weekday - 1;
// DateTime.weekday: 周一=1, 周二=2, ..., 周日=7
// 转换后: 周一=0, 周二=1, ..., 周日=6
```

### 7.3 列表页 (`lib/pages/list_page.dart`)

**页面组成：**

#### ① 时间维度切换 Tab（SegmentedButton / TabBar）
- 三个选项：**年 / 季度 / 月份**
- 切换时刷新下方列表和汇总数据

#### ② 筛选条件区（Row，多个 DropdownButton）
- **客户筛选**：DropdownButton，选项从 `getAllClientNames()` 动态获取
  - 默认值："全部"
- **类型筛选**：DropdownButton，选项从 `getAllProjectTypes()` 动态获取
  - 默认值："全部"
- **状态筛选**：DropdownButton，选项固定：全部 / 已结清 / 未结清
  - 默认值："全部"

#### ③ 顶部摘要卡片（Card，3 列等宽 Row）
| 指标 | 显示内容 | 颜色 |
|------|---------|------|
| 总金额 | ¥XXX,XXX.XX | 主色蓝 `#1677FF` |
| 项目数 | XX 个 | 成功绿 `#17A96E` |
| 已收款 | ¥XXX,XXX.XX | 主色蓝 `#1677FF` |

- 根据当前时间维度（年/季/月）+ 筛选条件动态计算

#### ④ 项目列表（ListView + Card）
每张项目卡片的布局：

```
┌─────────────────────────────────────┐
│ [项目名称]              ¥总金额     │
│ [客户名] · [类型]    [已收/未结清]  │
│ MM-DD ~ MM-DD                        │
└─────────────────────────────────────┘
```

- **第一行**：左侧项目名称（粗体），右侧总金额（蓝色大字）
- **第二行**：左侧客户名（灰色）+ 分隔点 + 类型标签（浅蓝背景），右侧结清状态标签
  - 已结清 → 绿色标签 `#17A96E`
  - 未结清 → 橙色标签 `#E87C17`
- **第三行**：日期范围 "起始日 ~ 截止日"（取 schedule_dates 最小和最大值的 MM-DD 格式）

**筛选逻辑**（组合过滤）：
1. 先按时间维度（年/季/月）筛选 `scheduleDates` 匹配的项目
2. 再按客户名称精确匹配（选"全部"则跳过）
3. 再按项目类型精确匹配（选"全部"则跳过）
4. 再按结清状态匹配（选"全部"则跳过）
5. 最终结果用于渲染列表 + 计算汇总

### 7.4 统计页 (`lib/pages/stats_page.dart`)

**页面组成：**

#### ① 年度指标卡区域（Row，2 列 Card）

| 指标卡 | 内容 |
|--------|------|
| 年度总收入 | ¥XXX,XXX.XX（蓝色大字，调用 `getYearTotal(year)`） |
| 项目数量 | XX 个（绿色大字，调用 `getYearProjectCount(year)`） |

- 年份跟随图表年份切换

#### ② 月度收入柱状图（fl_chart BarChart）
- X 轴：1 月 ~ 12 月
- Y 轴：收入金额（元）
- 每根柱子颜色：主题蓝 `#1677FF`
- 数据来源：逐月遍历项目，累加当月有 `scheduleDates` 的项目的 `total_amount`
- **Y 轴最大值保护**：如果全年收入全为 0，`maxY` 设为 1.0（避免除零崩溃）
- **年份导航**：左右箭头切换统计年份

#### ③ 项目类型分布饼图（fl_chart PieChart + ListView 图例）
- 扫描当年所有项目，按 `projectType` 分组统计金额占比
- 饼图配色方案（6 色）：
  1. `#1677FF`（蓝）
  2. `#17A96E`（绿）
  3. `#FF8C00`（橙）
  4. `#E84A3F`（红）
  5. `#9B59B6`（紫）
  6. `#1ABC9C`（青）
- 右侧/下方图例列表：颜色圆点 + 类型名 + 百分比 + 金额

#### ④ 客户金额占比饼图（同上样式）
- 按 `clientName` 分组统计金额占比

#### ⑤ 图表设置按钮（右上角图标）
- 点击弹出 BottomSheet，包含 3 个 SwitchListTile：
  - 显示/隐藏 月度收入柱状图
  - 显示/隐藏 类型分布饼图
  - 显示/隐藏 客户金额饼图
- 设置持久化到 SharedPreferences

### 7.5 设置页 (`lib/pages/settings_page.dart`)

**页面组成：**

#### ① 个人资料区（渐变色容器 Container）
- 圆形头像占位符（首字母或图标）
- 用户昵称（可编辑）
- 版本号 "v1.0.0"

#### ② 字段显示设置区（Section）
每个字段一个 SwitchListTile：

| 字段 | SharedPreferences Key | 默认值 |
|------|---------------------|--------|
| 客户名称 | field_clientName | true |
| 项目类型 | field_projectType | true |
| 项目总额 | field_totalAmount | true |
| 已收金额 | field_receivedAmount | true |
| 是否结清 | field_isSettled | true |
| 备注 | field_remarks | false |

- 控制列表页项目卡片中哪些字段可见

#### ③ 日历展示字段区（Section）
CheckboxListTile，最多选 **2 个**：

| 选项 | Key | 说明 |
|------|-----|------|
| 项目名称 | cal_projectName | 默认勾选 |
| 项目类型 | cal_projectType | 默认勾选 |
| 客户名称 | cal_clientName | 可选 |
| 项目总额 | cal_totalAmount | 可选 |
| 是否结清 | cal_isSettled | 可选 |

**校验逻辑**：
- 尝试勾选第 3 个时，弹出 SnackBar 提示"最多只能选择 2 个字段"
- 取消勾选不受限
- 校验在 setState **外部**执行（确保 return 能真正阻止状态更新）

#### ④ 账户设置区（Section）
- 修改昵称：弹出 AlertDialog（TextField + 确定/取消按钮）
  - 保存到 SharedPreferences（key: `nickname`）
- 修改头像：占位（TODO，需 image_picker 包）
- 应用锁密码：占位（TODO）

#### ⑤ 数据管理区（Section）
- 导出数据：调用 `exportCSV()` 生成 CSV 文件
  - 成功后提示文件路径
- 建议与反馈：占位（TODO）

---

## 八、配色方案（V1 蓝色系）

| 角色 | 色值 | 使用场景 |
|------|------|---------|
| 主题蓝 Primary | `#1677FF` | 主色调、选中态、按钮、今日高亮、金额文字 |
| Primary 浅色 | `rgba(22,119,255,0.08)` | 日历有项目格子的背景 |
| 成功绿 Success | `#17A96E` | 已结清标签、项目数指标、正数统计 |
| 警告橙 Warning | `#E87C17` | 未结清标签 |
| 错误红 Error | `#E84A3F` | 周末日期数字 |
| 深墨 Text | `#1A1A1A` | 标题、AppBar 文字、日历日期 |
| 正文 Gray | `#555555` | 次要文字 |
| 辅助 Gray | `#999999` | 未选中 Tab、说明文字 |
| 浅灰 Background | `#F5F6FA` | 页面背景色 |
| 卡片白 Card | `#FFFFFF` | 卡片背景、AppBar 背景 |
| 分割线 Border | `#E8EAED` | 边框、分割线 |

---

## 九、SharedPreferences Key 清单

| Key | 类型 | 默认值 | 用途 |
|-----|------|--------|------|
| nickname | String | "用户" | 用户昵称 |
| field_clientName | bool | true | 列表卡片是否显示客户名 |
| field_projectType | bool | true | 列表卡片是否显示类型 |
| field_totalAmount | bool | true | 列表卡片是否显示总额 |
| field_receivedAmount | bool | true | 列表卡片是否显示已收 |
| field_isSettled | bool | true | 列表卡片是否显示结清状态 |
| field_remarks | bool | false | 列表卡片是否显示备注 |
| cal_projectName | bool | true | 日历格子是否显示项目名 |
| cal_projectType | bool | true | 日历格子是否显示类型 |
| cal_clientName | bool | false | 日历格子是否显示客户名 |
| cal_totalAmount | bool | false | 日历格子是否显示总额 |
| cal_isSettled | bool | false | 日历格子是否显示结清状态 |
| show_bar_chart | bool | true | 统计页是否显示柱状图 |
| show_type_pie | bool | true | 统计页是否显示类型饼图 |
| show_client_pie | bool | true | 统计页是否显示客户饼图 |

---

## 十、Android 构建配置要点

### 10.1 `android/app/build.gradle.kts` 核心参数
```kotlin
namespace = "com.freelanceapp.freelance_app"
compileSdk = flutter.compileSdkVersion    // 由 Flutter 自动指定
minSdk = flutter.minSdkVersion            // 通常为 21
targetSdk = flutter.targetSdkVersion      // 通常为 35
```

### 10.2 Maven 镜像配置（已在代码中配置好）
- **依赖仓库**：`maven.aliyun.com/repository/google` + `/public`
- **插件仓库**：`maven.aliyun.com/repository/gradle-plugin` + `/google` + `/public`
- **Gradle 分发**：`mirrors.cloud.tencent.com/gradle/gradle-9.1.0-all.zip`

### 10.3 `gradle.properties` JVM 参数
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m
```

### 10.4 AndroidManifest.xml
- `android:label="freelance_app"`（显示名称）
- `launchMode="singleTop"`（防止重复创建 Activity）
- `windowSoftInputMode="adjustResize"`（软键盘弹出时调整布局）

---

## 十一、已知问题与修复记录

### 已修复的问题（复刻时无需再修，但需确认代码包含这些修改）

| # | 问题 | 文件 | 修复方式 |
|---|------|------|---------|
| 1 | V2/V3 紫色残留 | main.dart, schedule_page.dart | 全部改为 `#1677FF` 蓝色 |
| 2 | 图表 maxY 为 0 时崩溃 | stats_page.dart 第196行 | `.clamp(1.0, double.infinity)` |
| 3 | 复选框 return 不生效 | settings_page.dart 第186行 | 校验逻辑移至 setState 外部 |
| 4 | 日历周日位置错误 | schedule_page.dart 第52行 | `weekday == 7 ? 0 : weekday - 1` |

### 待注意的问题（不影响运行，但后续可能需要处理）

| # | 问题 | 说明 | 建议 |
|---|------|------|------|
| 1 | CSV 导出路径 | 使用 `getApplicationDocumentsDirectory()`，Android 上普通用户难以访问 | 后续考虑用 Downloads 目录 |
| 2 | Release 签名 | 当前使用 debug 签名 | 正式发布需配置 signingConfig |
| 3 | 应用图标 | 使用 Flutter 默认图标 | 需替换为自定义品牌图标 |
| 4 | 空状态 UI | 列表/统计页无数据时无空状态提示 | 建议补充 |
| 5 | 中文 key 编码 | SharedPreferences key 含中文，部分设备可能有兼容性问题 | 实测正常则保持 |

---

## 十二、复刻步骤清单（给程序员的使用指南）

### Phase 1：环境准备
- [ ] 安装 Flutter SDK（>=3.0.0）
- [ ] 配置国内镜像环境变量（FLUTTER_STORAGE_BASE_URL, PUB_HOSTED_URL）
- [ ] 安装 Android Studio 或 Android SDK command-line tools
- [ ] 运行 `flutter doctor` 确认环境 OK
- [ ] 连接测试手机或启动模拟器

### Phase 2：创建项目
- [ ] `flutter create --org com.freelanceapp --project-name freelance_app .`
- [ ] 替换 `pubspec.yaml` 为本文档第四章的内容
- [ ] 运行 `flutter pub get` 安装依赖

### Phase 3：实现数据层（按顺序）
- [ ] 创建 `lib/models/project.dart`（第五章完整代码）
- [ ] 创建 `lib/database/database_helper.dart`（第六章完整 API）

### Phase 4：实现 UI 层（按顺序）
- [ ] 创建 `lib/main.dart`（第七章 7.1 节规格）
- [ ] 创建 `lib/pages/schedule_page.dart`（第七章 7.2 节规格）
- [ ] 创建 `lib/pages/list_page.dart`（第七章 7.3 节规格）
- [ ] 创建 `lib/pages/stats_page.dart`（第七章 7.4 节规格）
- [ ] 创建 `lib/pages/settings_page.dart`（第七章 7.5 节规格）

### Phase 5：构建配置
- [ ] 替换 Android 构建配置文件（第十章）
- [ ] 配置 Maven 镜像（阿里云 + 腾讯云）

### Phase 6：验证
- [ ] `flutter run` 在真机上运行
- [ ] 逐一测试四个页面的所有交互功能
- [ ] 对照 prototype.html 原型检查 UI 一致性

---

## 十三、不应该变更的设计决策

以下是经过讨论确定的核心设计，**除非重新评审 PRD，否则不应变更**：

1. ✅ **单表 + JSON 日期数组**：不改为一对多关系表
2. ✅ **金额字段首次创建后不可编辑**：UI 不提供修改入口
3. ✅ **本地存储，不做云同步**：V1 不涉及网络功能
4. ✅ **底部导航 4 个 Tab**：日程 / 列表 / 统计 / 我的
5. ✅ **日历最多展示 2 个字段**：设置页 Checkbox 限制
6. ✅ **蓝色主题 #1677FF**：V1 配色方案
7. ✅ **仅竖屏**：不支持横屏
8. ✅ **project_name UNIQUE 约束**：同名 = 同一项目

---

## 十四、文件对照索引

| 本文档章节 | 对应源码文件 | 行数（约） |
|-----------|------------|----------|
| 第五章 数据模型 | `lib/models/project.dart` | ~95 行 |
| 第六章 数据库操作 | `lib/database/database_helper.dart` | ~280 行 |
| 第七章 7.1 入口 | `lib/main.dart` | ~90 行 |
| 第七章 7.2 日程页 | `lib/pages/schedule_page.dart` | ~440 行 |
| 第七章 7.3 列表页 | `lib/pages/list_page.dart` | ~280 行 |
| 第七章 7.4 统计页 | `lib/pages/stats_page.dart` | ~340 行 |
| 第七章 7.5 设置页 | `lib/pages/settings_page.dart` | ~250 行 |
| 第四章 依赖配置 | `pubspec.yaml` | ~30 行 |
| 第十章 Android 配置 | `android/**/*.kts`, `*.xml`, `*.properties` | ~200 行 |
| 第八章 配色 | CSS 变量 / Dart Color 常量 | — |
| 第九章 SP Keys | `settings_page.dart` + 各页面 | — |

---

*文档结束。如有疑问，参考 `PROGRESS.md`（开发进度快照）和 `PRD V1.1.0 开发版.md`（原始需求文档）。*
