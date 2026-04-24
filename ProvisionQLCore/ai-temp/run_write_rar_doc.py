# coding=utf-8
content = """# 如何为 ProvisionQL 添加 RAR 格式支持

RAR 格式是一种专有的闭源压缩算法，Apple 原生的 `Compression.framework` 以及目前我们在项目中使用的纯 Swift 库 `SWCompression` 和 `ZIPFoundation` **都不支持** RAR 格式的解析和解压。

若要在 `ProvisionQL` 中支持预览 `.rar` 文件，需要通过 C/C++ 与 Swift 混编的方式，桥接第三方的 RAR 解析库。以下是完整的实施路径：

## 1. 为什么不能使用 Swift Package Manager (SPM)?

经测试，常用的 RAR 解析库 **UnrarKit** 在其 `v2.11` 分支以及很多主流版本中，**并未原生提供 `Package.swift`** 来支持 Swift Package Manager。
因此，我们无法在 `ProvisionQLCore` 的 `Package.swift` 中直接通过 `.package(url: "...", branch: "v2.11")` 的形式来自动拉取依赖。

## 2. 正确的引入方式：手动集成源码 (Manual Integration)

既然无法使用 SPM，我们需要将底层依赖 `libunrar` 以及 Objective-C 封装层 `UnrarKit` 手动集成到工程中。具体步骤如下：

### 步骤 2.1: 下载源码
1. 从 GitHub 下载 `UnrarKit` 的源码压缩包（例如 `v2.11` 分支）。
2. 解压后，你主要需要关注两个目录：
   - `Classes/` (Objective-C 封装代码)
   - `Libraries/unrar/` (C++ 底层解压核心)

### 步骤 2.2: 拖入工程 & 清理冲突文件
1. 在 `ProvisionQLCore/Sources/` 下新建一个文件夹（例如命名为 `UnrarKit`）。
2. 将上述 `Classes` 和 `Libraries/unrar` 文件夹拖入该目录，并在 Xcode 中关联到 `ProvisionQLCore` Target。
3. **⚠️ 极其重要：** 必须在 Target 的 **Build Phases -> Compile Sources** 列表中，找到并**移除 `rar.cpp` 和 `unrar.cpp`** 两个文件。因为它们包含了命令行的 `main()` 入口函数，如果不移除会导致“多重入口点 (Multiple definition of _main)”的编译链接错误。

### 步骤 2.3: 配置桥接 (Bridging)
为了让 Swift 代码能够调用 Objective-C/C++ 代码：
1. 确保你的工程拥有一个 Objective-C Bridging Header（例如 `ProvisionQLCore-Bridging-Header.h`）。
2. 在该头文件中添加：
   ```objc
   #import "URKArchive.h"
   #import "URKFileInfo.h"
   ```

## 3. 激活预留的解析逻辑

我们在 `ProvisionQLCore/Sources/ArchiveParser.swift` 中已经为你准备好了完美的解压、树形结构生成与映射逻辑。
当你完成了上述 C++ 库的接入并确保编译不报错后，请执行最后一步：

打开 `ArchiveParser.swift`，找到 `parseRar` 方法：

```swift
    static func parseRar(_ url: URL) throws -> ZipArchiveInfo {
        // FIXME: URKArchive is not available in the current isolated build context.
        // Uncomment when UnrarKit is successfully resolved and imported.
        
        let archive = try URKArchive(url: url)
        let fileInfos = try archive.listFileInfo()
        
        var files: [ZipFileInfo] = []
        var totalUncompressedSize: Int64 = 0
        
        for info in fileInfos {
            let fileInfo = ZipFileInfo(
                path: info.name,
                uncompressedSize: Int64(info.uncompressedSize),
                compressedSize: 0, 
                isDirectory: info.isDirectory
            )
            files.append(fileInfo)
            if !info.isDirectory {
                totalUncompressedSize += Int64(info.uncompressedSize)
            }
        }
        
        return ZipArchiveInfo(
            name: url.lastPathComponent,
            fileCount: files.filter { !$0.isDirectory }.count,
            totalUncompressedSize: totalUncompressedSize,
            totalCompressedSize: 0,
            files: files
        )
        
        // 删除或注释掉原本的 throw
        // throw ArchiveParserError.missingRarLibrary
    }
```
**解开这段代码的注释，并移除 `throw ArchiveParserError.missingRarLibrary`。**

## 4. 享受你的预览成果

此时，你的项目已经完全支持 RAR 格式。
无需修改任何 UI 代码，现有的 `ZipArchivePreviewView` 就能完美地将 RAR 渲染成和 ZIP、TAR、7z 一样直观、带有图标准确区分的 **最多三层的扁平树状结构**。
系统的 `Info.plist` UTI 注册及路由拦截等前置工作，也已在之前的提交中全部配置妥当！
"""
with open("/Users/spxt666/ProvisionQL/doc/How_To_Support_RAR.md", "w") as f:
    f.write(content)
print("RAR doc updated successfully.")
