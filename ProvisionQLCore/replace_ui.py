import sys
with open("/Users/spxt666/ProvisionQL/Preview/PreviewViewController.swift", "r") as f:
    content = f.read()

marker = "struct ZipArchivePreviewView: View {"
if marker in content:
    base_content = content[:content.index(marker)]
    new_view = r"""struct ZipRootItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var isDirectory: Bool
    var size: Int64
    var itemCount: Int
}

struct ZipArchivePreviewView: View {
    let archiveInfo: ZipArchiveInfo
    let fileURL: URL?

    var rootItems: [ZipRootItem] {
        var dict: [String: ZipRootItem] = [:]
        for file in archiveInfo.files {
            let normalizedPath = file.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let components = normalizedPath.components(separatedBy: "/")
            guard let first = components.first, !first.isEmpty else { continue }
            let name = first
            let isDir = components.count > 1 || file.isDirectory
            
            if var existing = dict[name] {
                existing.size += file.uncompressedSize
                if components.count > 1 || !file.isDirectory {
                     existing.itemCount += 1
                }
                existing.isDirectory = existing.isDirectory || isDir
                dict[name] = existing
            } else {
                let initialCount = (components.count > 1 || !file.isDirectory) ? 1 : 0
                dict[name] = ZipRootItem(name: name, isDirectory: isDir, size: file.uncompressedSize, itemCount: initialCount)
            }
        }
        
        return dict.values.sorted {
            if $0.isDirectory == $1.isDirectory {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.isDirectory && !$1.isDirectory
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.Padding.standard) {
                header()
                
                GroupBox {
                    VStack(alignment: .leading, spacing: UIConstants.Padding.medium) {
                        InfoRow(label: "Total Files", value: "\(archiveInfo.fileCount)")
                        InfoRow(label: "Uncompressed Size", value: formatBytes(archiveInfo.totalUncompressedSize))
                        InfoRow(label: "Compressed Size", value: formatBytes(archiveInfo.totalCompressedSize))
                    }
                }
                
                section(title: "Root Contents (ls -la)") {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 0) {
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
                            
                            ForEach(Array(rootItems.enumerated()), id: \.element.id) { index, item in
                                HStack {
                                    Image(systemName: item.isDirectory ? "folder.fill" : "doc.text")
                                        .foregroundColor(item.isDirectory ? .blue : .gray)
                                        .frame(width: 24, alignment: .leading)
                                    
                                    Text(item.name)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    
                                    Spacer()
                                    
                                    if item.isDirectory {
                                        Text("\(item.itemCount) items")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                            .frame(width: 80, alignment: .trailing)
                                    }
                                    
                                    Text(formatBytes(item.size))
                                        .font(.caption.monospacedDigit())
                                        .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.vertical, 6)
                                
                                if index < rootItems.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                
                if let fileURL = fileURL {
                    section(title: "Archive Info") {
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
    with open("/Users/spxt666/ProvisionQL/Preview/PreviewViewController.swift", "w") as f:
        f.write(base_content + new_view)
    print("Success")
else:
    print("Marker not found")
