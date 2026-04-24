import sys

filepath = "/Users/spxt666/ProvisionQL/Preview/PreviewViewController.swift"
with open(filepath, "r") as f:
    content = f.read()

marker = "struct ZipRootItem: Identifiable, Hashable {"
if marker in content:
    start_idx = content.find(marker)
else:
    print("Marker not found, please check the file.")
    sys.exit(1)

base_content = content[:start_idx]

new_view = """struct ZipNode {
    let name: String
    var isDirectory: Bool
    var size: Int64
    var itemCount: Int
    var children: [ZipNode]
}

struct FlatZipNode: Identifiable {
    let id = UUID()
    let name: String
    let isDirectory: Bool
    let size: Int64
    let itemCount: Int
    let depth: Int
}

struct ZipArchivePreviewView: View {
    let archiveInfo: ZipArchiveInfo
    let fileURL: URL?

    var flatItems: [FlatZipNode] {
        class Node {
            var name: String
            var isDirectory: Bool = false
            var size: Int64 = 0
            var children: [String: Node] = [:]
            init(name: String) { self.name = name }
        }
        
        let root = Node(name: "root")
        root.isDirectory = true
        
        for file in archiveInfo.files {
            let path = file.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if path.isEmpty { continue }
            let components = path.components(separatedBy: "/")
            
            var current = root
            for (i, component) in components.enumerated() {
                let isLast = (i == components.count - 1)
                let isDir = isLast ? file.isDirectory : true
                
                if current.children[component] == nil {
                    current.children[component] = Node(name: component)
                }
                let next = current.children[component]!
                next.isDirectory = next.isDirectory || isDir
                next.size += file.uncompressedSize
                current = next
            }
        }
        
        func toStructNode(_ node: Node) -> ZipNode {
            let sortedChildren = node.children.values.sorted {
                if $0.isDirectory == $1.isDirectory {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.isDirectory && !$1.isDirectory
            }.map { toStructNode($0) }
            
            return ZipNode(name: node.name, isDirectory: node.isDirectory, size: node.size, itemCount: node.children.count, children: sortedChildren)
        }
        
        let rootNodes = root.children.values.sorted {
            if $0.isDirectory == $1.isDirectory {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.isDirectory && !$1.isDirectory
        }.map { toStructNode($0) }
        
        func flatten(_ nodes: [ZipNode], depth: Int, maxDepth: Int) -> [FlatZipNode] {
            var result: [FlatZipNode] = []
            for node in nodes {
                result.append(FlatZipNode(name: node.name, isDirectory: node.isDirectory, size: node.size, itemCount: node.itemCount, depth: depth))
                if node.isDirectory && depth < maxDepth {
                    result.append(contentsOf: flatten(node.children, depth: depth + 1, maxDepth: maxDepth))
                }
            }
            return result
        }
        
        // 0 = root items, 1 = subfolders, 2 = grand-subfolders (3 levels total)
        return flatten(rootNodes, depth: 0, maxDepth: 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.Padding.standard) {
                header()
                
                GroupBox {
                    VStack(alignment: .leading, spacing: UIConstants.Padding.medium) {
                        InfoRow(label: "Total Files", value: "\\(archiveInfo.fileCount)")
                        InfoRow(label: "Uncompressed Size", value: formatBytes(archiveInfo.totalUncompressedSize))
                        InfoRow(label: "Compressed Size", value: formatBytes(archiveInfo.totalCompressedSize))
                    }
                }
                
                section(title: "Archive Tree (Up to 3 Levels)") {
                    GroupBox {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Name")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Size")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .padding(.bottom, 8)
                            
                            Divider()
                            
                            let allItems = flatItems
                            let items = Array(allItems.prefix(1000))
                            
                            ForEach(Array(items.enumerated()), id: \\.element.id) { index, item in
                                HStack(spacing: 6) {
                                    if item.depth > 0 {
                                        Spacer()
                                            .frame(width: CGFloat(item.depth * 20))
                                        Image(systemName: "arrow.turn.down.right")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.gray.opacity(0.4))
                                    }
                                    
                                    Image(systemName: item.isDirectory ? "folder.fill" : "doc.text")
                                        .foregroundColor(item.isDirectory ? .blue : .gray)
                                        .frame(width: 20, alignment: .center)
                                    
                                    Text(item.name)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    
                                    Spacer()
                                    
                                    if item.isDirectory {
                                        Text("\\(item.itemCount) items")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                            .frame(width: 80, alignment: .trailing)
                                    }
                                    
                                    Text(formatBytes(item.size))
                                        .font(.caption.monospacedDigit())
                                        .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.vertical, 6)
                                
                                if index < items.count - 1 {
                                    Divider()
                                }
                            }
                            
                            if allItems.count > 1000 {
                                Divider()
                                Text("... and \\(allItems.count - 1000) more items (truncated for preview)")
                                    .italic()
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                        }
                    }
                }
                
                if let fileURL = fileURL {
                    section(title: "File Info") {
                        FileInfoSection(fileURL: fileURL)
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: UIConstants.Window.minWidth, minHeight: UIConstants.Window.minHeight)
    }
}

private extension ZipArchivePreviewView {
    func header() -> some View {
        HStack(alignment: .top, spacing: UIConstants.Padding.large) {
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
                .fill(Color.gray.opacity(0.3))
                .frame(width: UIConstants.Size.iconSize, height: UIConstants.Size.iconSize)
                .overlay(
                    Image(systemName: "doc.zipper")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: UIConstants.Padding.small) {
                Text(archiveInfo.name)
                    .font(.title)
                    .fontWeight(.bold)
                    
                Text("ZIP Archive")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .fontWeight(.semibold)
                .font(.title2)
            content()
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
"""

with open(filepath, "w") as f:
    f.write(base_content + new_view)

print("UI successfully updated to Tree view.")
