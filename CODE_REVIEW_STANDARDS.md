# 自由派项目代码审查标准与流程

> **版本**: V1.0 | **制定日期**: 2026-06-24
> **适用范围**: freelance_app（自由派 Flutter 项目）及后续所有代码提交

---

## 一、审查目标

| 优先级 | 目标 | 说明 |
|--------|------|------|
| P0 | 正确性 | 代码逻辑正确，不产生运行时崩溃或数据错误 |
| P1 | 安全性 | 无 SQL 注入、无敏感数据泄露、权限正确 |
| P2 | 可维护性 | 命名清晰、结构合理、新人能快速理解 |
| P3 | 性能 | 无明显浪费（N+1 查询、不必要的重建等） |
| P4 | 规范性 | 遵循项目既定的编码风格和模式 |

---

## 二、审查流程

### 2.1 提交前自检（作者必做）

每次提交代码前，作者必须确认：

- [ ] `flutter analyze` 无 error（warning 尽量清零）
- [ ] 新功能有对应的数据层 + UI 层变更
- [ ] 涉及数据库 schema 变更时更新 DEVELOPER_GUIDE.md
- [ ] commit message 格式：`类型: 简述`（如 `fix: 修复日历星期计算错误`）

### 2.2 审查触发条件

以下情况**必须**发起代码审查：

| 触发条件 | 审查级别 |
|----------|----------|
| 修改 database_helper.dart 或 project.dart | 🔴 全量审查（P0+P1） |
| 修改页面核心逻辑（非纯 UI 调整） | 🟡 标准审查（P0-P2）|
| 纯 UI / 样式调整 | 💭 快速审查（P3+P4） |
| 新增依赖包（pubspec.yaml 变更） | 🟡 标准审查 |
| 修改 pubspec.yaml 版本号（仅版本升级） | 💭 快速审查 |

### 2.3 审查步骤

```
1. 作者提交 PR / 发起审查请求
       ↓
2. 审查者阅读 DEVELOPER_GUIDE.md 了解上下文
       ↓
3. 审查者按「三、审查 Checklist」逐项检查
       ↓
4. 审查者输出审查报告（使用「四、审查报告格式」）
       ↓
5. 作者修复问题并回复
       ↓
6. 审查者确认 → 通过 / 继续修改
       ↓
7. 合并代码
```

---

## 三、审查 Checklist（按文件类型）

### 3.1 数据模型（project.dart 或新增 model）

#### 🔴 Blocker（必须通过）

- [ ] **字段映射完整**: toMap() 和 fromMap() 字段一一对应，无遗漏
- [ ] **JSON 序列化安全**: scheduleDates 的 jsonEncode/jsonDecode 有容错（try-catch）
- [ ] **类型转换正确**: REAL 类型字段用 `.toDouble()`，INTEGER 用 `== 1` 判断 bool
- [ ] **默认值合理**: 构造函数中金额默认 0.0、isSettled 默认 false
- [ ] **时间戳一致**: createdAt 统一用 `DateTime.now().millisecondsSinceEpoch`

#### 🟡 Should Fix

- [ ] **命名规范**: Dart camelCase，数据库 snake_case，映射关系清晰
- [ ] **辅助方法有单元测试覆盖**: hasDate / hasDateInYear 等判断方法

### 3.2 数据库操作（database_helper.dart 或新 DAO）

#### 🔴 Blocker

- [ ] **SQL 参数化**: 所有用户输入必须用 `whereArgs` 参数化查询，禁止字符串拼接
- [ ] **表结构一致性**: _createDB 的 CREATE TABLE 与 Project.toMap() 字段完全匹配
- [ ] **事务操作**: 多步写操作（如 appendDates 的读→改→写）应考虑事务包裹
- [ ] **错误处理**: 数据库操作应有 try-catch，不能让未捕获异常导致崩溃
- [ ] **资源关闭**: close() 方法可调用，单例不会造成连接泄漏

#### 🟡 Should Fix

- [ ] **查询效率**: 避免全表查询后内存过滤（V1 可接受，但需注释标注 TODO）
- [ ] **方法职责单一**: 每个方法只做一件事

### 3.3 页面组件（*_page.dart）

#### 🔴 Blocker

- [ ] **空状态处理**: 列表/图表为空时有友好提示（不能白屏或崩溃）
- [ ] **数值边界保护**: 除法有零检查、图表 maxY 有最小值保护、数组访问不越界
- [ ] **异步操作正确**: async/await 使用正确，无遗漏的 await
- [ ] **setState 合规**: setState 内不做耗时操作，return 能真正阻止执行流
- [ ] **内存泄漏防护**: TextEditingController 在 dispose 时释放（StatelessWidget 中的 controller 注意生命周期）

#### 🟡 Should Fix

- [ ] **Widget 拆分**: 单个 build 方法超过 150 行时应拆分子 Widget
- [ ] **常量提取**: 颜色值、字号、间距等重复使用的值应定义为常量
- [ ] **Magic Number 消除**: 数字字面量（如 padding: 12, borderRadius: 14）应有语义注释
- [ ] **交互反馈**: 可点击元素有 onTap/ onPressed，loading 状态有明确指示

#### 💭 Nit

- [ ] **代码格式**: 遵循 dart format
- [ ] **import 整理**: 无未使用的 import

### 3.4 配置文件（pubspec.yaml）

#### 🔴 Blocker

- [ ] **YAML 格式正确**: 缩进严格为 2 空格，无 TAB
- [ ] **依赖版本兼容**: SDK 约束 `>=3.0.0 <4.0.0`
- [ ] **environment 块干净**: 不含 flutter: 版本约束（不属于 environment）

---

## 四、审查报告格式

每次审查输出统一使用以下格式：

```markdown
## Code Review：[PR标题/commit描述]

### 总体评价
[一段话概括整体质量：优秀/良好/需改进/需重做]

### 🔴 必须修复 (Blocker)
| # | 文件:行号 | 问题 | 建议 |
|---|-----------|------|------|
| B1 | schedule_page.dart:52 | 星期计算在周日时会越界 | 改为 `(weekday == 7 ? 0 : weekday - 1)` |

### 🟡 建议修复 (Suggestion)
| # | 文件:行号 | 问题 | 建议 |
|---|-----------|------|------|
| S1 | list_page.dart:120 | _loadData 每次都全量查询 | 考虑本地缓存 |

### 💭 小建议 (Nit)
| # | 文件:行号 | 问题 |
|---|-----------|------|
| N1 | stats_page.dart:88 | _colors 可以提取为全局常量 |

### ✅ 亮点
- [值得肯定的地方]

### 结论
[通过 / 需修改后重新审查]
```

---

## 五、项目特有规则（自由派）

### 5.1 数据模型铁律

```
⛔ 禁止：
   - 将一个项目的多个日期拆成多条数据库记录
   - 修改已有项目的 total_amount / received_amount / is_settled
   - 创建同名的新项目（必须走 appendDates 逻辑）

✅ 必须：
   - schedule_dates 存 JSON 数组字符串
   - 项目名唯一（UNIQUE 约束）
   - 同名输入 → 追加日期，保留原金额信息
```

### 5.2 配色铁律

```
✅ 主色统一使用 Color(0xFF1677FF) — 蓝色
✅ 成功/已结清 = Color(0xFF17A96E) — 绿色
✅ 警告/未结清 = Color(0xFFE87C17) — 橙色
✅ 错误/周末 = Color(0xFFE84A3F) — 红色
⛔ 禁止引入新的主色调（V2/V3/V4 的紫色系已废弃）
```

### 5.3 页面结构铁律

```
✅ 底部导航固定 4 个 Tab：日程 / 列表 / 统计 / 我的
✅ 日历年份范围 2021 ~ 2099
✅ 日历格子最多显示 2 个项目标签
✅ 日历格子展示字段最多选 2 个（设置页限制）
⛔ 不改变底部导航数量和顺序
```

### 5.4 导入规范

```dart
// ✅ 正确顺序
import 'dart:core';          // 1. Dart 核心库
import 'package:flutter/...'; // 2. Flutter / 第三方包
import 'package:intl/...';    //    （按字母排序）
import 'package:sqflite/...'; //
import '../models/...';        // 3. 相对路径（先 models）
import '../database/...';      //    再 database
import 'pages/...';           //    最后 pages
```

---

## 六、审查工具配置

### 推荐的 IDE 配置

1. **Flutter lint 规则**（已在 pubspec.yaml 引入 `flutter_lints: ^3.0.0`）
2. **analysis_options.yaml**（建议添加）:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - avoid_print: true
    - prefer_const_constructors: true
    - prefer_const_declarations: true
    - sort_child_properties_last: true
    - use_key_in_widget_constructors: true
```

### 静态分析命令

```bash
# 全量分析
flutter analyze

# 详细输出
flutter analyze -v

# 仅 errors
flutter analyzer --no-fatal-infos --no-fatal-warnings
```

---

## 七、审查角色与职责

| 角色 | 职责 | 要求 |
|------|------|------|
| **作者** | 提交代码、自检、回复审查意见、修复问题 | 对自己的代码质量负责 |
| **审查者** | 按 Checklist 审查、输出报告、确认修复 | 熟悉项目架构和数据模型 |
| **Maintainer** | 合并代码、解决冲突、更新文档 | 有最终否决权 |

### 审查时效要求

- 审查者收到请求后 **24 小时** 内给出首次审查意见
- 作者修复后 **4 小时** 内通知审查者复审
- 复审确认后 **当天内**合并

---

## 八、常见反模式速查

| 反模式 | 正确做法 |
|--------|----------|
| `"SELECT * FROM tb_project WHERE name = '$userInput'"` | `db.query('tb_project', where: 'name = ?', whereArgs: [userInput])` |
| `setState(() { return; })` 中调用 `_save()` | 先校验再 setState，return 后 _save 不执行 |
| `maxY: data.max`（data 为空时 max 为 0） | `data.max.clamp(1.0, double.infinity)` |
| `Color(0xFFxxxxxx)` 硬编码到处都是 | 定义主题常量或从 Theme.of(context) 获取 |
| 一个 StatefulWidget 500+ 行 | 拆分为多个子 Widget 或抽取 StateMixin |
| `getAllProjects()` 后内存过滤大数据集 | 改为 SQL WHERE 子句（加 TODO 注释） |
| 直接用数字做颜色/字号 | 定义语义常量：`static const kPrimaryColor = Color(0xFF1677FF)` |

---

*本标准由代码审查专家制定，随项目演进持续更新。*
