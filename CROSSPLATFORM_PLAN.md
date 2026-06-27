# 自由派 —— 跨平台（iOS + Android）开发方案

> **版本**: V1.0 | **日期**: 2026-06-24
> **制定人**: 移动应用开发工程师
> **现状**: 已有完整 Flutter 项目（7 个 Dart 文件，~1688 行），Android 可运行，需扩展至 iOS

---

## 一、核心结论

### 好消息：你的代码已经是跨平台的 ✅

**Flutter 天然支持 iOS + Android + Web + Desktop**，你现在的代码 **不需要重写一行业务逻辑**。

| 平台 | 当前状态 | 需要做的事 |
|------|---------|-----------|
| **Android** | ✅ 可编译、可运行 | 打包发布即可 |
| **iOS** | ⚠️ 代码已就绪，缺构建环境 | 配置 Xcode → `flutter run` |
| **Web**（未来可选） | 代码大部分兼容 | 需替换 sqflite 为 web 数据库方案 |

---

## 二、技术架构总览

```
┌─────────────────────────────────────────────┐
│              自由派 App                       │
│                                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──┐ │
│  │ 日程页   │ │ 列表页   │ │ 统计页   │ │设│ │
│  │schedule │ │ list    │ │ stats   │ │置│ │
│  └────┬────┘ └────┬────┘ └────┬────┘ └──┘ │
│       │           │           │            │
│  ┌────▼───────────▼───────────▼──────────┐ │
│  │         业务逻辑层（纯 Dart）          │ │
│  │  Project 模型 / 筛选逻辑 / 图表计算     │ │
│  └────────────────────┬──────────────────┘ │
│                       │                     │
│  ┌────────────────────▼──────────────────┐ │
│  │        数据访问层（平台抽象）          │ │
│  │  DatabaseHelper (sqflite)             │ │
│  │  SharedPreferences                   │ │
│  └────┬─────────────────────────────┬────┘ │
│       │                             │       │
│  ┌────▼──────┐              ┌───────▼───┐  │
│  │ Android   │              │   iOS      │  │
│  │ SQLite    │              │  SQLite   │  │
│  │ NSPref*   │              │ UserDefaults│ │
│  └───────────┘              └───────────┘  │
└─────────────────────────────────────────────┘

关键点：
- lib/ 下所有 .dart 文件 = 平台无关的纯 Dart 代码，iOS/Android 共用
- sqflite 在两个平台上都是原生 SQLite 实现，API 完全一致
- shared_preferences 同理，iOS 用 NSUserDefaults / Android 用 SharedPreferences
- 只有 android/ 和 ios/ 目录是平台特定的原生代码
```

---

## 三、iOS 支持路线图

### Phase 1：环境准备（必须 macOS）

#### 3.1 硬件与系统要求

| 项目 | 要求 | 说明 |
|------|------|------|
| **Mac 电脑** | Apple Silicon (M1/M2/M3) 或 Intel Mac | iOS 开发必须有 Mac，没有替代方案 |
| **macOS 版本** | Monterey (12+) 或更高 | Xcode 15+ 需要 |
| **内存** | 8GB 起步，16GB+ 推荐 | Xcode + 模拟器很吃内存 |
| **硬盘空间** | 至少 40GB 可用 | Xcode 本身 ~15GB，加上模拟器 |

> **没有 Mac？** 见「八、无 Mac 替代方案」

#### 3.2 安装 Xcode

```bash
# 从 App Store 安装 Xcode（免费）
# 或从 developer.apple.com 下载 Xcode 15+

# 安装后打开一次 Xcode，接受许可协议
sudo xcode-select --install
sudo xcodebuild -license accept
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

#### 3.3 安装 CocoaPods（Flutter iOS 依赖管理）

```bash
# Flutter 的 iOS 插件依赖 CocoaPods
brew install cocoapods

# 验证安装
pod --version
```

#### 3.4 验证 iOS 开发环境

```bash
# 在 Mac 上执行
flutter doctor

# 预期输出应包含:
# [✓] Xcode (develop for iOS)
# [✓] CocoaPods
```

---

### Phase 2：iOS 项目配置

#### 4.1 当前 iOS 目录状态

`freelance_app/ios/` 目录已存在（Flutter 自动生成的标准脚手架）：

```
ios/
├── Runner.xcworkspace/          # Xcode 工作区（用这个打开）
├── Runner.xcodeproj/            # Xcode 工程
├── Runner/
│   ├── AppDelegate.swift         # 应用入口（标准模板）
│   ├── Info.plist               # 应用配置清单
│   ├── Assets.xcassets/         # 图标资源（默认 Flutter 图标）
│   └── Base.lproj/              # Storyboard（启动屏）
├── Flutter/                      # Flutter 框架文件
├── Podfile                      # CocoaPods 依赖声明
└── Podfile.lock                 # 依赖版本锁
```

#### 4.2 需要修改的配置

##### ① `ios/Runner/Info.plist` — 添加权限和配置

当前是默认配置，需要添加：

```xml
<key>CFBundleDisplayName</key>
<string>自由派</string>

<!-- 如果后续需要 CSV 导出到 Files App -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<false/>
```

> V1 阶段不需要相机/相册/位置等权限，所以不需要额外申请隐私权限。

##### ② `ios/Runner/Assets.xcassets/AppIcon.appiconset` — 替换应用图标

准备一套 iOS 图标（1024x1024 源图），然后用 Xcode 的 Asset Catalog 自动生成各尺寸。

##### ③ `ios/Runner.xcodeproj/project.pbxproj` — 部署目标

确保 `IPHONEOS_DEPLOYMENT_TARGET` 设置为 **iOS 14.0+**（Flutter 3.x 要求最低 iOS 12，但建议 14 以获得更好的 API）。

```bash
# 检查当前设置
grep IPHONEOS_DEPLOYMENT_TARGET ios/Runner.xcodeproj/project.pbxproj
```

#### 4.3 Pod 依赖安装

首次在 iOS 上构建时，需要先安装原生依赖：

```bash
cd ios
pod install
cd ..
```

这会为 sqflite、path_provider、shared_preferences 等 Flutter 插件下载对应的 iOS 原生框架（FMDBSQLite、Reachability 等）。

---

### Phase 3：构建与调试 iOS

#### 5.1 连接真机或启动模拟器

**方式 A：iPhone 真机**
```bash
# 用 USB 连接 iPhone，信任此电脑后
flutter devices
# 应能看到类似 "Zaore's iPhone (mobile)" 的设备

flutter run -d <device-id>
```

**方式 B：iOS 模拟器**
```bash
# 启动 iPhone 16 Pro 模拟器
open -a Simulator

flutter run
# 自动检测到运行的模拟器并部署
```

#### 5.2 构建命令速查

| 命令 | 用途 |
|------|------|
| `flutter run` | Debug 模式运行（默认自动选择设备） |
| `flutter run -d iphone` | 运行到 iPhone 模拟器 |
| `flutter run -d all` | 同时运行所有设备 |
| `flutter run --release` | Release 模式运行（性能接近正式版） |
| `flutter build ios --release` | 构建 Release 包（用于上传 App Store） |
| `flutter build ipa --release` | 生成 `.ipa` 安装包 |

---

### Phase 4：iOS 发布准备

#### 6.1 Apple Developer 账号

| 类型 | 价格 | 适用场景 |
|------|------|---------|
| **个人账号** | $99/年 | 个人开发者，可上架 App Store |
| **公司账号** | $99/年 | 团队开发，多人协作 |
| **企业账号** | $299/年 | 内部分发，不上架 |
| **免费用法** | 免费 | 只能在自己的设备上测试（每 7 天需重签） |

#### 6.2 证书与描述文件流程

```
1. 登录 developer.apple.com
       ↓
2. 创建 App ID（Bundle Identifier: com.freelanceapp.freelance_app）
       ↓
3. 创建 Development / Distribution 证书
       ↓
4. 注册测试设备（UDID）
       ↓
5. 创建 Provisioning Profile
       ↓
6. Xcode 中 Signing & Capabilities 配置
       ↓
7. flutter build ipa --release
       ↓
8. 上传到 App Store Connect 或分发安装
```

#### 6.3 App Store 上架检查清单

- [ ] 应用图标符合规范（圆角透明、无 alpha 通道）
- [ ] 启动屏幕适配（iPhone SE ~ iPhone 16 Pro Max 全尺寸）
- [ ] 支持深色模式（Material 3 默认支持，但需要实际测试）
- [ ] 无崩溃、无内存泄漏（Xcode Instruments 检查）
- [ ] 隐私政策页面（App Store 要求）
- [ ] App 截图（6.7" 和 5.5" 各一组）
- [ ] App 分类：效率 / 工具类
- [ ] App 描述和关键词优化

---

## 四、Android 发布（补充完善）

当前 Android 已可运行，发布前还需完成以下步骤：

### 4.1 应用签名

```bash
# 生成签名密钥（只需做一次）
keytool -genkey -v -keystore freelance-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias freelance-key

# 将 jks 放到 android/app/ 目录下（不要提交到 Git！）

# 配置 android/app/build.gradle.kts 引用签名
```

### 4.2 `android/app/build.gradle.kts` 关键配置

```kotlin
android {
    namespace = "com.freelanceapp.freelance_app"
    compileSdk = 35          // 编译 SDK
    minSdk = 21              // 最低支持 Android 5.0
    targetSdk = 35           // 目标 SDK
    
    defaultConfig {
        applicationId = "com.freelanceapp.freelance_app"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        
        // 多 DPI 支持
        vectorDrawables.useSupportLibrary = true
    }
    
    signingConfigs {
        create("release") {
            storeFile = file("freelance-release.jks")
            storePassword = "<your-password>"
            keyAlias = "freelance-key"
            keyPassword = "<your-password>"
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            
            // 代码混淆（V1 可选，V2 建议）
            // isMinifyEnabled = true
            // proguardFiles += ...
        }
    }
}
```

### 4.3 构建 APK/AAB

```bash
# APK（直接安装）
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk

# AAB（上传 Google Play / 国内应用商店）
flutter build appbundle --release
# 输出: build/app/outputs/bundle/release/app-release.aab
```

### 4.4 国内应用商店清单

| 商店 | 特点 | 推荐度 |
|------|------|--------|
| **华为应用市场** | 用户量大，审核严格 1-3 天 | ⭐⭐⭐⭐⭐ |
| **小米应用商店** | 审核快，覆盖面广 | ⭐⭐⭐⭐⭐ |
| **OPPO/vivo/应用宝** | 补充渠道 | ⭐⭐⭐⭐ |
| **Google Play** | 海外用户 | 视需求 |

---

## 五、双平台一致性保障策略

### 5.1 UI 自适应原则

| 问题 | Flutter 解决方案 | 当前代码状态 |
|------|-----------------|-------------|
| 屏幕尺寸差异 | `MediaQuery` + `Expanded` / `Flexible` | ✅ 已使用 |
| 安全区域（刘海/灵动岛等） | `SafeArea` widget | ❌ 未使用，**需要添加** |
| 字体大小缩放 | `TextScaleFactor` / `MediaQuery.textScaleFactor` | ⚠️ 未显式处理 |
| 深色模式 | `ThemeData.dark()` / `ThemeData.light()` | ❌ 仅浅色主题 |
| 导航手势 | Flutter CupertinoApp（iOS）vs MaterialApp（Android） | ✅ MaterialApp 双端可用 |
| 滑动返回（iOS） | `CupertinoPageScaffold` / `PageRouteBuilder` | ❌ 未处理 |

### 5.2 必须修复的双平台问题

#### 🔴 P0：添加 SafeArea

所有页面根 Widget 应包裹 `SafeArea`：

```dart
// main.dart 和每个 _page.dart 的 build 方法中
@override
Widget build(BuildContext context) {
  return SafeArea(        // ← 新增
    child: Scaffold(
      // ...现有内容
    ),
  );
}
```

不包裹的话，在 iPhone（有刘海/灵动岛）上内容会被遮挡。

#### 🟡 P1：深色模式适配（可选，V1 不强制）

```dart
// main.dart
themeMode: ThemeMode.system,  // 跟随系统
darkTheme: ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
),
```

#### 🟡 P1：iOS 风格微调

```dart
// 底部导航栏在 iOS 上的表现
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  selectedFontSize: 11,
  unselectedFontSize: 11,
  elevation: 8,  // iOS 阴影更明显
)
```

---

## 六、代码改动量评估

| 改动项 | 影响范围 | 工作量 | 优先级 |
|--------|---------|--------|--------|
| 添加 SafeArea 到所有页面 | 5 个 .dart 文件 | 10 分钟 | 🔴 必须 |
| iOS Info.plist 配置 | 1 个 plist 文件 | 5 分钟 | 🔴 必须 |
| `pod install` 首次初始化 | ios/ 目录 | 自动 | 🔴 必须 |
| 应用图标替换 | Assets.xcassets | 设计工作 | 🟡 应该 |
| iOS 签名与打包 | Xcode + 命令行 | 30 分钟 | 🟡 应该 |
| 深色模式适配 | main.dart + 各页面 | 1-2 小时 | 💭 可选 |
| iOS 滑动手势 | 页面路由配置 | 30 分钟 | 💭 可选 |
| Android 签名配置 | build.gradle.kts | 20 分钟 | 🟡 应该 |
| Android 多语言/多 DPI | res/ 目录 | 设计工作 | 💭 可选 |

**总计：iOS 核心支持约 1 小时工作量（不含设计和审核时间）**

---

## 七、项目文件变更清单

### iOS 新增/修改文件

```
ios/Runner/Info.plist              ← 修改：添加 CFBundleDisplayName + 文件共享
ios/Runner/Assets.xcassets/        ← 替换：自定义图标
ios/Podfile                        ← 可能修改：如需指定 platform :ios 版本
ios/Podfile.lock                   ← 自动更新：pod install 后生成
```

### Android 修改文件

```
android/app/freelance-release.jks   ← 新增：签名密钥（不入 Git）
android/app/build.gradle.kts        ← 修改：签名配置 + 版本号
android/app/src/main/res/           ← 替换：图标 + 启动屏
```

### Dart 代码修改

```
lib/main.dart                      ← 修改：添加 SafeArea
lib/pages/schedule_page.dart        ← 修改：添加 SafeArea
lib/pages/list_page.dart            ← 修改：添加 SafeArea
lib/pages/stats_page.dart           ← 修改：添加 SafeArea
lib/pages/settings_page.dart        ← 修改：添加 SafeArea
```

---

## 八、无 Mac 时的替代方案

如果你暂时没有 Mac，有以下选择：

### 方案 A：云服务构建 iOS

| 服务 | 价格 | 特点 |
|------|------|------|
| **Codemagic** | 免费额度 500 分/月 | 专为 Flutter 打造，一键构建 |
| **Bitrise** | 免费额度有限 | 支持 iOS/Android CI/CD |
| **GitHub Actions** | 免费（公开仓库） | self-hosted runner 需 Mac |
| **Firebase App Distribution** | 免费 | 构建后的分发 |

### 方案 B：租用 Mac 云主机

| 服务 | 价格 | 说明 |
|------|------|------|
| **MacStadium** | ~$50/月起 | 托管式远程 Mac |
| **AWS EC2 Mac** | ~$65/小时（按需） | 按需实例 |
| **阿里云 ECS（macOS）** | ~¥300/月起 | 国内网络友好 |

### 方案 C：先用 Android 发布，iOS 后续补

这是最务实的路径——先把 Android 版上线，同时寻找 Mac 资源。因为 **Dart 代码完全共用**，后续加 iOS 只是配置层面的工作。

---

## 九、推荐实施路径

```
Week 1                    Week 2-3                  Week 4+
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌──────────────┐      ┌──────────────┐         ┌──────────────┐
│ ① Android    │      │ ② iOS 环境   │         │ ③ 双平台     │
│   发布就绪   │ ───→ │   配置+构建   │ ───→→  │   同步迭代   │
│              │      │              │         │              │
│ - 签名配置   │      │ - 获取 Mac   │         │ - Bug 修复   │
│ - APK/AAB   │      │ - 安装 Xcode │         │ - 功能增强   │
│ - 上架国内   │      │ - pod install│         │ - 性能优化   │
│   应用商店   │      │ - flutter run│         │ - 用户反馈   │
└──────────────┘      └──────────────┘         └──────────────┘
     ↑                                              ↑
     │                                              │
  现在就能做                                    有 Mac 后开始
```

---

## 十、下一步行动项

### 立即可做（今天）

- [ ] **给所有页面加 SafeArea**（10 分钟，防止 iOS 内容被遮挡）
- [ ] **配置 Android 签名**，生成 release APK
- [ ] **运行 `flutter analyze`** 清除 warning，提升代码质量

### 有 Mac 后（预计 1 天）

- [ ] 安装 Xcode + CocoaPods
- [ ] `flutter doctor` 验证通过
- [ ] `cd ios && pod install && cd .. && flutter run`
- [ ] 在 iOS 模拟器和真机上验证 4 个页面功能
- [ ] 替换应用图标和启动屏
- [ ] 构建 IPA 测试版

### 发布前（额外 1-2 周）

- [ ] 申请 Apple Developer 账号
- [ ] 准备 App Store 元数据（截图/描述/关键词）
- [ ] 提交审核

---

*本方案基于当前 Flutter 3.44.2 代码库制定，所有 Dart 代码无需重写。*
