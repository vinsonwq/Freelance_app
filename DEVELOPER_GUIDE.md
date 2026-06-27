# 自由派（freelance_app）开发者复刻指南

> **版本**: V1.0.0 | **最后更新**: 2026-06-24
> **用途**: 供其他程序员完整复刻现有功能，无需依赖原始对话记录。

---

## 一、项目概览

| 项目 | 说明 |
|------|------|
| 产品名 | 自由派 |
| 定位 | 自由职业者日程 + 财务一体管家 App |
| 技术栈 | Flutter 3.44.2 + Dart 3.x + SQLite (sqflite) |
| 平台 | Android（首选），未来考虑 iOS/Web |
| 设计基准 | `prototype.html`（V1 原型，蓝灰商务风） |
| 主色 | `#1677FF`（蓝色）、成功绿 `#17A96E`、警告橙 `#E87C17`、危险红 `#E84A3F` |

### 核心功能

1. **日程页**：日历月视图 + 点击日期添加日程
2. **列表页**：项目台账 + 时间/客户/类型/状态筛选
3. **统计页**：年度指标卡 + 月度柱状图 + 类型/客户饼图
4. **设置页**：个人中心 + 字段开关 + 日历字段选择 + CSV 导出

---

## 二、环境搭建

### 必装软件

| 软件 | 版本 | 用途 | 安装方式 |
|------|------|------|----------|
| Flutter SDK | 3.44.2+ stable | 跨平台框架 | 解压到 `D:\flutter`，bin 加入 PATH |
| Android SDK | 36.1.0 | Android 编译 | 随 Android Studio 安装 |
| Android Studio | 2026.18+ | IDE / SDK 管理 | 官网下载安装 |
| Visual Studio | 2019/2022/2024 | **C++ 工作负载**（必须！） | VS Installer 勾选"使用 C++ 的桌面开发" |

### 关键配置

```powershell
# 环境变量（用户级别）
ANDROID_HOME = C:\Users\Zaore\AppData\Local\Android\Sdk
FLUTTER_STORAGE_BASE_URL = https://storage.flutter-io.cn
PUB_HOSTED_URL = https://pub.flutter-io.cn

# PATH 追加
D:\flutter\bin
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\cmdline-tools\latest\bin   # 注意：实际路径可能是 cmdline-tools\cmdline-tools\bin
```

### 验证命令

```bash
flutter doctor          # 应显示 [✓] Flutter / Android toolchain / Connected device
flutter --version       # 应显示 3.44.2+
```

### ⚠️ 已知坑

1. **sdkmanager 路径问题**：Android Studio 安装后，`cmdline-tools` 的实际结构是 `cmdline-tools/cmdline-tools/bin/`，但 Flutter 期望 `cmdline-tools/latest/bin/`。需要手动复制一份：
   ```powershell
   $src = "$env:USERPROFILE\AppData\Local\Android\Sdk\cmdline-tools\cmdline-tools"
   $dst = "$env:USERPROFILE\AppData\Local\Android\Sdk\cmdline-tools\latest"
   New-Item -ItemType Directory -Path $dst -Force | Out-Null
   Copy-Item -Path "$src\*" -Destination $dst -Recurse -Force
   ```

2. **Visual Studio C++ 工作负载是编译 Android App 的前置条件**！没有它 `flutter run` 会一直卡在 Gradle 编译阶段。

3. **首次运行 `flutter` 命令会触发 Dart SDK 初始化**（Building flutter tool...），国内网络下可能需 5-15 分钟。

---

## 三、项目初始化

```bash
# 1. 创建 Flutter 项目
flutter create --org com.freelance --project-name freelance_app

# 2. 进入项目目录
cd freelance_app

# 3. 安装依赖
flutter pub get

# 4. 运行
flutter run
```

---

## 四、文件结构与职责

```
freelance_app/
├── pubspec.yaml                          # 项目配置与依赖包声明（25 行）
├── lib/
│   ├── main.dart                         # 入口文件：App 主题 + 底部导航栏（108 行）
│   ├── models/
│   │   └── project.dart                  # 数据模型：Project 类（83 行）
│   ├── database/
│   │   └── database_helper.dart          # SQLite 操作：CRUD + 统计 + 导出（198 行）
│   └── pages/
│       ├── schedule_page.dart            # 日程页：日历 + 添加弹窗（442 行，最大文件）
│       ├── list_page.dart                # 列表页：台账 + 筛选（279 行）
│       ├── stats_page.dart               # 统计页：图表（338 行）
│       └── settings_page.dart            # 设置页：个人中心（247 行）
└── android/                              # Android 原生配置（自动生成）
    └── app/
        └── build.gradle.kts              # Android 构建配置
```

**总代码量**: 约 1720 行 Dart 代码（8 个源文件）

---

## 五、数据模型（核心设计决策）

### 表结构：tb_project

```sql
CREATE TABLE tb_project (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  project_name    TEXT NOT NULL UNIQUE,     -- 项目名称（唯一约束）
  schedule_dates  TEXT NOT NULL,             -- JSON 数组：["2026-01-15", "2026-02-20"]
  client_name     TEXT,                       -- 客户名称
  project_type    TEXT,                       -- 项目类型
  total_amount    REAL DEFAULT 0.0,           -- 项目总额
  received_amount REAL DEFAULT 0.0,           -- 已收金额
  is_settled      INTEGER DEFAULT 0,          -- 是否结清 (0/1)
  remarks         TEXT,                       -- 备注
  created_at      INTEGER NOT NULL            -- 创建时间戳（毫秒）
);
```

### 核心设计决策（V1 锁定，不可变更）

1. **一个项目 = 一条数据库记录**：不按日期拆分记录
2. **多个日期用 JSON 数组存储在 `schedule_dates` 字段**
3. **`project_name` 是 UNIQUE**：同名项目只存在一条，后续追加日期而非新建
4. **金额字段（total_amount / received_amount / is_settled）在首次创建后不可修改**：如果用户输入已存在的项目名，金额保持原值不变，仅追加日期
5. **不做云同步**：所有数据存储在设备本地 SQLite

### Project 模型类（project.dart）

```dart
class Project {
  int? id;
  String projectName;           // → project_name
  List<String> scheduleDates;   // → JSON → schedule_dates
  String? clientName;           // → client_name
  String? projectType;          // → project_type
  double totalAmount;           // → total_amount
  double receivedAmount;        // → received_amount
  bool isSettled;               // → is_settled (0/1)
  String? remarks;              // → remarks
  int createdAt;                // → created_at (millisecondsSinceEpoch)
}
```

**关键方法**:
- `toMap()` → 序列化为数据库行（scheduleDates 用 jsonEncode，isSettled 转 0/1）
- `fromMap()` → 反序列化（JSON 解析有容错 catch）
- `hasDate(year, month)` → 判断项目是否在某月有日程
- `hasDateInYear(year)` → 判断项目是否在某年有日程

---

## 六、数据库操作（database_helper.dart）

### 设计模式

- **单例模式**: `DatabaseHelper.instance`
- **懒加载**: 首次访问 `database` getter 时初始化
- **存储位置**: `getApplicationDocumentsDirectory()/freelance.db`

### API 清单

#### CRUD 操作

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `createProject(project)` | Project 对象 | int (新 ID) | 插入新项目 |
| `getProjectByName(name)` | 项目名称 | Project? | 按名称查找（用于去重判断） |
| `appendDates(name, newDates)` | 名称+日期列表 | int (影响行数) | 向已有项目追加日期（合并去重排序后更新） |
| `deleteProject(id)` | 项目 ID | int | 删除项目 |
| `getAllProjects()` | 无 | List<Project> | 全量查询，按 created_at DESC |

#### 按时间筛选

| 方法 | 说明 |
|------|------|
| `getProjectsByYear(year)` | 内存过滤：检查 hasDateInYear() |
| `getProjectsByMonth(year, month)` | 内存过滤：检查 hasDate(year, month) |
| `getProjectsByQuarter(year, quarter)` | 内存过滤：检查季度内三个月 |
| `getProjectsByDate(date)` | 精确匹配 YYYY-MM-DD 格式字符串 |

> **注意**：时间筛选全部在内存中完成（先 getAllProjects 再 filter）。对于 V1 数据量（几十到几百个项目）足够高效。如果未来数据量增大，应改为 SQL WHERE 子句。

#### 辅助查询

| 方法 | 说明 |
|------|------|
| `getAllProjectNames()` | 获取所有项目名（用于自动补全） |
| `getAllClientNames()` | 获取去重客户名列表（用于筛选下拉） |
| `getAllProjectTypes()` | 获取去重类型列表（用于筛选下拉） |

#### 统计方法

| 方法 | 说明 |
|------|------|
| `getYearTotal(year)` | 年度总收入 |
| `getYearReceived(year)` | 年度已收款 |
| `getYearProjectCount(year)` | 年度项目数 |

#### 导出

| 方法 | 说明 |
|------|------|
| `exportCSV()` | 导出到 `{documentsDir}/freelance_export_{timestamp}.csv`，返回文件路径 |

---

## 七、页面详解

### 7.1 日程页（schedule_page.dart）— 442 行

**UI 结构**:
```
AppBar（标题"日程"+ 右上角"+"按钮）
├── 年/月 选择器行（DropdownButton × 2 + 左右箭头按钮）
├── 星期标题行（日 一 二 三 四 五 六）
└── GridView 日历格子（7列，childAspectRatio: 0.85）
```

**核心逻辑**:

1. **日历构建 (`_buildCalendarCells`)**:
   - 以**周一**为每周第一天：`startWeekday = (firstDay.weekday - 1) % 7`
   - 上月末补齐 + 当月日期 + 下月补齐
   - 年份范围限制：2021 ~ 2099
   - 今日高亮：蓝色填充背景 + 白色文字
   - 周末日期：红色文字（周六日）
   - 有日程的日期：显示项目标签（最多 2 个，截断 4 字符）

2. **点击日期 → 弹出 `_AddProjectSheet`**:
   - 输入项目名称时实时调用 `_checkExisting` 检查是否已存在
   - **已存在**：只显示项目名输入框，提示"已关联已有项目"，保存时只追加日期
   - **不存在**：显示完整表单（客户、类型、总额、已收、结清开关、备注）

3. **右上角"+"按钮**: 快速添加今日日程

### 7.2 列表页（list_page.dart）— 279 行

**UI 结构**:
```
AppBar（标题"项目列表"）
├── 白色卡片容器
│   ├── 时间 Tab 栏（年 / 季度 / 月份）
│   ├── 筛选器行（客户下拉 + 类型下拉 + 状态下拉）
│   └── 汇总栏（总金额 | 项目数 | 已收款）
└── ListView 项目卡片列表（空状态显示"暂无数据"）
```

**核心逻辑**:

1. **三种时间维度**: `_timeMode ∈ {year, quarter, month}`，切换时重新加载数据
2. **筛选器**: 客户/类型从数据库动态获取选项；状态固定为 {全部, 已结清, 未结清}
3. **汇总计算**: 在 `_loadData` 中遍历筛选结果累加 totalAmount 和 receivedAmount
4. **项目卡片**: 显示项目名 + 金额 + 类型标签(蓝底) + 结清状态标签(绿/橙底) + 日期区间

### 7.3 统计页（stats_page.dart）— 338 行

**UI 结构**:
```
AppBar（标题"统计"+ 右上角设置图标）
├── 滚动视图
│   ├── 指标卡行（年度总收入 | 总项目数）
│   ├── 月度收入柱状图（可切换年份）
│   ├── 项目类型分布饼图
│   └── 客户金额占比饼图
```

**核心逻辑**:

1. **指标卡**: 从 `getProjectsByYear` 获取数据，累加 totalAmount 和 count
2. **柱状图 (fl_chart BarChart)**:
   - 12 根柱子代表 12 个月
   - 月收入计算逻辑：遍历项目的 scheduleDates，按月份归属累加 totalAmount
   - **maxY 保护**: `.clamp(1.0, double.infinity)` 防止全零时渲染异常
   - 可通过左右箭头切换年份（2021~2099）
3. **饼图 (fl_chart PieChart)**:
   - 类型分布：按 projectType 分组聚合 totalAmount（null 归为"未分类"）
   - 客户分布：按 clientName 分组聚合 totalAmount（null 归为"未指定"）
   - 固定 6 色循环配色
4. **图表可见性**: 通过 SharedPreferences 持久化三个开关（show_bar_chart / show_type_pie / show_client_pie），设置入口在右上角对话框

### 7.4 设置页（settings_page.dart）— 247 行

**UI 结构**:
```
AppBar（标题"我的"）
├── 个人资料区（渐变头像 + 昵称 + 版本号）
├── "字段显示设置" 分组
│   └── SwitchListTile × 6（客户名称/类型/总额/已收/结清/备注）
├── "日历格子展示（最多选2个）" 分组
│   └── CheckboxListTile × 5（项目名称/类型/客户/总额/结清）
├── "账户" 分组
│   ├── 修改昵称（AlertDialog + TextField）
│   ├── 修改头像（占位，未实现）
│   └── 应用锁密码（占位，未实现）
└── "数据" 分组
    ├── 导出 CSV（调用 DatabaseHelper.exportCSV）
    └── 建议与反馈（占位）
```

**核心逻辑**:

1. **持久化**: 所有设置通过 SharedPreferences 存储读取
2. **日历字段限制**: 最多选 2 个，超限时 SnackBar 提示并阻止
3. **校验逻辑修复**: Checkbox 的 onChanged 回调中先校验再 setState，return 能真正阻止超限

---

## 八、主题系统

### 配色 Token（V1 蓝色系）

| 常量值 | 用途 |
|--------|------|
| `#1677FF` | 主色：按钮、高亮、Tab 选中态、金额文字、链接 |
| `#69B1FF` | 主色浅：头像渐变终点 |
| `#17A96E` | 成功绿：已结清标签、正向统计数字 |
| `#E87C17` | 警告橙：未结清标签 |
| `#E84A3F` | 危险红：周末日期颜色 |
| `#F5F6FA` | 页面背景灰 |
| `#FFFFFF` | 卡片/容器背景 |
| `#E8EAED` | 边框/分割线 |
| `#1A1A1A` | 主标题文字 |
| `#999999` | 辅助文字/次要信息 |
| `#555555` | 正文文字 |
| `#CCCCCC` | 禁用/占位图标 |

### 主题配置（main.dart）

```dart
ThemeData(
  primaryColor: Color(0xFF1677FF),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF1677FF),
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1A1A1A),
    elevation: 0,
    centerTitle: false,
  ),
)
```

---

## 九、依赖包详情

| 包名 | 版本 | 引入页面 | 用途 |
|------|------|----------|------|
| `sqflite` | ^2.3.0 | database_helper.dart | SQLite 数据库操作 |
| `path_provider` | ^2.1.0 | database_helper.dart, settings_page.dart | 获取应用文档目录路径 |
| `intl` | ^0.19.0 | schedule_page.dart, list_page.dart, stats_page.dart | 日期格式化 |
| `fl_chart` | ^0.68.0 | stats_page.dart | 柱状图 (BarChart) + 饼图 (PieChart) |
| `shared_preferences` | ^2.2.0 | stats_page.dart, settings_page.dart | 设置项持久化存储 |

---

## 十、数据流图

```
用户操作                    页面层                      数据层
─────────                  ──────                      ──────

点击日期 ─────────────→  SchedulePage               DatabaseHelper
                           │                            │
                           ├→ _onDateTap()             │
                           │   └→ showModalBottomSheet  │
                           │      └→ _AddProjectSheet   │
                           │         ├→ _checkExisting  ├→ getProjectByName()
                           │         └→ _save()         ├→ createProject()
                           │                             ├→ appendDates()

切换筛选 ─────────────→  ListPage                   DatabaseHelper
                           │                            │
                           ├→ _loadData()               │
                           │   ├→ getProjectsBy*Month()  ├→ getAllProjects()
                           │   ├→ getAllClientNames()   ├→ (内存过滤)
                           │   └→ getAllProjectTypes()  │
                           └→ _buildProjectCard()

查看统计 ─────────────→  StatsPage                  DatabaseHelper
                           │                            │
                           ├→ _loadData()               │
                           │   └→ getProjectsByYear()   ├→ getAllProjects()
                           │                             ├→ (内存聚合)
                           └→ _build*Chart()

修改设置 ─────────────→  SettingsPage               SharedPreferences
                           │                            │
                           ├→ _savePrefs()             ├→ setString/setBool
                           ├→ _loadPrefs()             ├→ getString/getBool
                           └→ _exportData()            DatabaseHelper
                                                        └→ exportCSV()
```

---

## 十一、未实现功能（预留接口）

| 功能 | 当前状态 | 对应位置 |
|------|----------|----------|
| 修改头像 | 占位（onTap: {}） | settings_page.dart |
| 应用锁密码 | 占位（onTap: {}） | settings_page.dart |
| 建议与反馈 | 占位（onTap: {}） | settings_page.dart |
| 字段显隐对日程表单的影响 | 开关已做但未联动到 _AddProjectSheet | settings_page ↔ schedule_page |
| 日历格子上展示所选字段 | _calFields 已存储但未渲染到日历格子 | settings_page ↔ schedule_page |
| 编辑已有项目 | 不支持（只能删除重建或追加日期） | — |
| 从项目中移除单个日期 | 不支持 | — |
| 空状态插图 | 仅文字"暂无数据" | list_page.dart |

---

## 十二、已知 Bug 与修复记录

### 已修复 ✅

| 问题 | 文件 | 修复内容 | 修复日期 |
|------|------|----------|----------|
| 颜色混用 V2/V3 紫色残留 | main.dart, schedule_page.dart | 统一改为 `#1677FF` 蓝色 | 2026-06-23 |
| 图表 maxY 为零导致崩溃 | stats_page.dart 第196行 | 添加 `.clamp(1.0, double.infinity)` | 2026-06-23 |
| 复选框 return 无法阻止状态更新 | settings_page.dart 第186行 | 校验逻辑移到 setState 外 | 2026-06-23 |
| 星期计算错误 | schedule_page.dart | `(weekday - 1) % 7` 正确处理周一开头 | 2026-06-19 |
| pubspec.yaml environment 错误 | pubspec.yaml | 移除 flutter 约束 | 2026-06-19 |

### 待验证 ⚠️

| 问题 | 文件 | 说明 |
|------|------|------|
| SQL 三引号语法 | database_helper.dart 第31-44行 | `'''...'''` 多行字符串写法需在实际编译中验证 |
| CSV 导出路径权限 | database_helper.dart exportCSV | Android 13+ 需要 MANAGE_EXTERNAL_STORAGE 或 READ_MEDIA 权限 |
| 中文 SharedPreferences key | settings_page.dart | key 含中文（如 `field_客户名称`），某些设备可能编码异常 |

---

## 十三、复刻 Checklist

如果你要从头复刻此项目，按以下顺序执行：

### Phase 1: 环境准备（预计 30-60 分钟）
- [ ] 安装 Flutter SDK 并加入 PATH
- [ ] 安装 Android Studio + Android SDK
- [ ] 接受 Android 许可证（`flutter doctor --android-licenses`）
- [ ] **安装 Visual Studio C++ 工作负载**（否则无法编译 Android）
- [ ] `flutter doctor` 通过（Chrome/VS 警告可忽略）
- [ ] 配置国内镜像环境变量

### Phase 2: 项目初始化（10 分钟）
- [ ] `flutter create` 新项目
- [ ] 复制 `pubspec.yaml` 并 `flutter pub get`
- [ ] 确认依赖安装成功（无版本冲突）

### Phase 3: 数据层（30 分钟）
- [ ] 创建 `lib/models/project.dart` — Project 类
- [ ] 创建 `lib/database/database_helper.dart` — DatabaseHelper 单例
- [ ] 验证：数据库能正常创建和增删改查

### Phase 4: UI 层（2-3 小时）
- [ ] `main.dart` — 入口 + 主题 + 底部导航
- [ ] `schedule_page.dart` — 日历 + 添加弹窗（最复杂，优先做）
- [ ] `list_page.dart` — 列表 + 筛选
- [ ] `stats_page.dart` — 图表
- [ ] `settings_page.dart` — 设置

### Phase 5: 联调测试（1 小时）
- [ ] 添加一个项目 → 日历显示 ✓
- [ ] 同名项目追加日期 → 金额不变 ✓
- [ ] 切换月份/年份 → 日历正确 ✓
- [ ] 列表页筛选 → 结果正确 ✓
- [ ] 统计页图表 → 数据一致 ✓
- [ ] 设置页开关 → 重启后保留 ✓
- [ ] CSV 导出 → 文件可打开 ✓

### Phase 6: 打包发布
- [ ] 更新应用图标
- [ ] 更新启动屏
- [ ] `flutter build apk --release`
- [ ] 签名 APK

---

## 十四、架构改进建议（V1.1/V2 参考）

当前代码是 V1 MVP，以下是有价值但不阻塞发布的改进方向：

1. **状态管理**: 当前使用 setState 直接管理，建议升级为 Provider / Riverpod
2. **时间筛选 SQL 化**: 将 `getAllProjects` 后的内存过滤改为 SQL WHERE 子句
3. **编辑/删除功能**: 支持编辑项目信息和移除单日期
4. **字段联动**: settings_page 的开关真正控制 schedule_page 表单字段显隐
5. **日历字段渲染**: _calFields 选择的内容显示在日历格子上
6. **单元测试**: 至少覆盖 Project.fromMap/toMap 和 DatabaseHelper CRUD
7. **错误边界**: 数据库操作统一 try-catch + 用户友好提示
8. **国际化**: 字符串提取为 arb 文件（虽然目前只有中文）

---

*本文档由 AI 根据实际源码生成，保证与代码一致。如有疑问以源码为准。*
