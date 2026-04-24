# ProvisionQL 增强版

ProvisionQL 是一款专为 macOS 设计的 QuickLook 插件，旨在为开发者提供各种应用包和归档文件的即时预览功能。

## 最新增强功能

在最新版本中，我们通过集成原生 Swift 解析库，全面扩展了对 Android 应用包以及通用压缩归档格式的支持。

### 1. Android APK 支持
- **应用信息提取**：自动解析 `AndroidManifest.xml`，提取应用名称、包名、版本号及构建版本。
- **权限预览**：原生展示 APK 请求的所有系统权限列表。
- **图标渲染**：采用智能搜索算法，从 APK 资源中提取高清图标，并应用 iOS 风格的圆角裁切展示。

### 2. 多格式归档文件预览 (.zip, .7z, .tar, .tar.gz)
- **树状层级展示**：不再是简单的文件列表，而是支持最高 **3 层深度** 的树形目录结构，带缩进和层级指引。
- **实时统计**：显示每个文件夹包含的项目数量及其总解压大小。
- **文件详情**：展示每个文件的原始大小、名称，并使用 SF Symbols 区分文件与文件夹。

## 支持的文件格式

| 类别 | 扩展名 | 说明 |
| :--- | :--- | :--- |
| **Apple 应用** | `.ipa`, `.xcarchive`, `.appex`, `.app` | iOS/macOS 应用包及扩展 |
| **Android 应用** | `.apk` | Android 应用程序包 |
| **配置 profile** | `.mobileprovision`, `.provisionprofile` | Apple 预置描述文件 |
| **压缩归档** | `.zip`, `.7z`, `.tar`, `.gz`, `.tgz` | 通用归档格式 (基于 SWCompression) |

## 技术架构

- **核心库 (`ProvisionQLCore`)**：
  - `AppArchiveParser`: 统一的应用包解析入口。
  - `ArchiveParser`: 负责 Zip、7z、Tar 等格式的跨平台解析。
  - `IconExtractor`: 针对不同平台的图标智能提取引擎。
- **依赖技术栈**：
  - `SwiftAXML`: 纯 Swift 实现的 Android 二进制 XML 解析。
  - `ZIPFoundation`: 高性能 ZIP 归档处理。
  - `SWCompression`: 针对 7z, LZMA, Tar 的 Swift 原生解析支持。
  - `SwiftUI`: 现代化的 QuickLook 预览界面。

## 安装与构建

1. 克隆仓库。
2. 在项目根目录运行 `xcodebuild -resolvePackageDependencies`。
3. 使用 Xcode 打开 `ProvisionQL.xcodeproj` 并构建 `ProvisionQL` Scheme。
4. 构建生成的 App 运行后，系统将自动注册 QuickLook 扩展。

---
*由 Gemini 协助开发与增强。*
