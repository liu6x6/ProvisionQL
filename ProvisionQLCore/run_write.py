# coding=utf-8
content = """# ProvisionQLCore 增强与 APK 原生解析功能技术总结

本文档详细记录了本次针对 `ProvisionQL` 及核心库 `ProvisionQLCore` 的修复与功能升级过程。主要解决了项目的构建依赖问题，并全面增强了对 Android 安装包 (.apk) 的原生解析支持，包括 **应用权限 (Permissions)** 和 **应用图标 (Icon)** 的提取与可视化展示。

---

## 1. 核心架构与依赖梳理

`ProvisionQL` 是一款 QuickLook 插件工具，负责在 macOS 快速预览各类应用安装包。核心解析逻辑由相对独立的 `ProvisionQLCore` 承担，依赖以下第三方库：
- **ZIPFoundation**: 负责基础的文件解压操作。
- **SwiftAXML**: 负责解析 Android 特有的二进制 XML (AXML) 格式（如 `AndroidManifest.xml`）。

```mermaid
graph TD
    UI[ProvisionQL QuickLook UI]
    Core[ProvisionQLCore 解析库]
    AXML[SwiftAXML: AXML 解析器]
    ZIP[ZIPFoundation: ZIP 解压缩]

    UI -->|依赖| Core
    Core -->|解压 IPA, APK, APPEX| ZIP
    Core -->|解析 AndroidManifest.xml| AXML
```

### 1.1 解决 Xcode 与 SwiftPM 依赖锁定问题
**背景**：在 `ProvisionQLCore` 中，因 `SwiftAXML` 主分支 (main) 的 commit hash 缓存过时，导致 Xcode 与命令行构建时报出“找不到 Product 'SwiftAXML'”的严重错误。同时，由于沙盒网络代理问题，Xcode 无法从 GitHub 拉取最新代码。
**解决方案**：
1. 更新 `ProvisionQLCore` 的 `Package.swift`，从依赖分支 (`branch: "main"`) 变更为强绑定已知稳定且合法的 commit 节点 (`revision: "b7e8b99a141fc82da444423731b8b71588d6b6d0"`)。
2. 强制清理并重建了 Xcode 的 `DerivedData` 和 SwiftPM 缓存。
3. 清理了 `ProvisionQLCore` 源码中由于早期试验残留的被废弃的 `aapt2` 可执行文件与相关废弃代码，消除所有编译警告。

---

## 2. APK 权限 (Permissions) 解析与可视化

**目标**：将 Android APK 的应用权限以类似 iOS “Entitlements” 的高亮方式展示给用户，并通过公共 API 提供访问。

### 2.1 数据模型扩展 (AppInfo.swift)
在提供给 UI 的统一数据结构 `AppInfo` 中新增 `permissions: [String]` 字段。

```mermaid
classDiagram
    class AppInfo {
      +String name
      +String bundleIdentifier
      +String version
      +String buildNumber
      +NSImage? icon
      +ProvisioningInfo? embeddedProvisioningProfile
      +Dictionary~String, EntitlementValue~ entitlements
      +Array~String~ permissions
      +Array~String~ deviceFamily
      +String? minimumOSVersion
      +String? sdkVersion
    }
```

### 2.2 解析与绑定 (AppArchiveParser.swift)
在 `parseAPK` 方法中，使用 `AXMLManifestParser` 提取 XML 中的 `<uses-permission>` 节点，并直接赋值给 `AppInfo` 的 `permissions` 属性。
*逻辑变更*：过去为了省事，将 Android 权限硬塞入 iOS 专属的 `entitlements` 字典中。现在进行了严格分离，`entitlements` 保持为空字典，`permissions` 专职存放 Android 权限。

### 2.3 UI 适配 (AppArchivePreviewView.swift)
在 QuickLook UI 中引入了动态呈现逻辑：
1. **添加组件**：创建了专门渲染权限列表的 `PermissionsSection` 视图。
2. **隔离渲染**：当传入的 `AppInfo` 的 `permissions` 不为空时，底部单独渲染出一个 "Permissions" 块。移除了以前临时显示的 "apk has no entitlements" 的硬编码警告信息。

---

## 3. APK 应用图标 (Icon) 智能提取算法

**目标**：在不依赖外部工具（如 `aapt2`）的前提下，从压缩包中智能且准确地抽出 APK 的最高清启动图标，并裁切成统一的圆角效果。

### 3.1 算法流程设计
提取图标的逻辑封装在 `IconExtractor.extractFromAPK` 中，采用了“双轨制”搜索策略：

```mermaid
flowchart TD
    Start((开始解析 APK 图标))
    Extract[ZIPFoundation 读取 APK 文件目录树]
    
    SearchPrimary{检查标准高优路径}
    PrimaryHit((优先命中))
    
    FuzzySearch{进入动态模糊评分查找}
    Score[遍历 res/ 目录下所有 png/webp]
    CalcScore[根据关键字 xxxhdpi, launcher, icon 计算得分]
    PickBest[选取最高得分路径]
    FuzzyHit((模糊命中))
    
    ApplyCorner[通过 applyRoundedCorners 切圆角]
    ReturnImage((返回 NSImage 显示至 UI))
    ReturnNil((返回 nil 显示占位图))

    Start --> Extract
    Extract --> SearchPrimary
    
    SearchPrimary -- 命中 --> PrimaryHit
    SearchPrimary -- 未命中 --> FuzzySearch
    
    FuzzySearch --> Score
    Score --> CalcScore
    CalcScore --> PickBest
    
    PickBest -- 找到得分最高的图 --> FuzzyHit
    PickBest -- 根本没找到图片 --> ReturnNil
    
    PrimaryHit --> ApplyCorner
    FuzzyHit --> ApplyCorner
    
    ApplyCorner --> ReturnImage
```

### 3.2 搜索策略详解

1. **标准路径池匹配 (Preferred Dirs & Names)**
   - **预设目录** (优先级递减)：
     `res/mipmap-xxxhdpi` > `res/mipmap-xxhdpi` > `res/mipmap-xhdpi` ... > `drawable-xxxhdpi` ... > 基础 `mipmap` & `drawable`。
   - **预设文件名** (支持自适应圆角图标)：
     `ic_launcher_round.png` > `ic_launcher.png` > `app_icon.png` > `icon.png` > `logo.png` (包括 `.webp` 格式)。
   - **自适应兼容**：在遍历时，会自动检测附加了 `-v26` 后缀的变体路径。

2. **全盘动态打分回退机制 (Fuzzy Search Fallback)**
   如果开发者的应用采用了非标准命名（比如被混淆或自定义了资源路径），系统会遍历归档文件树，对所有位于 `res/` 并且是 `.png` 或 `.webp` 的文件进行关键词打分：
   - 包含 `launcher` 或 `icon` 为有效基准。
   - `xxxhdpi` (+60分), `xxhdpi` (+50分), `xhdpi` (+40分), `hdpi` (+30分), `mdpi` (+20分)。
   - 带有 `round` (+5分)。
   最后提取打分最高的图片作为应用主图标。

3. **视觉对齐 (Post-processing)**
   提取到的原始图像会调用 `applyRoundedCorners(to:)` API，将其处理为与 iOS/macOS 视觉一致的 22.5% 圆角矩形图，完美融入 `ProvisionQL` 的统一设计规范。

---

## 4. 总结

通过本次修复与功能增强，`ProvisionQL` 已具备成熟且原生的 Android APK 解析能力。不再依赖已过时的外部 C++ 或 Java 二进制工具（如 `aapt2`），纯 Swift 的原生解析链路 (`SwiftAXML` + `ZIPFoundation`) 极大提升了项目的安全性、稳定性以及在最新 macOS 与 Xcode 环境下的兼容性。同时，完善的权限信息提取和精准的高清图标呈现，为用户提供了统一、直观的使用体验。
"""
with open("/Users/spxt666/ProvisionQL/doc/ProvisionQL_APK_Support_Summary.md", "w") as f:
    f.write(content)
print("Doc written successfully.")
