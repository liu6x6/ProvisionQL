//
//  TableSection.swift
//  Preview
//
//  Created by Evgeny Aleksandrov

import SwiftUI

struct TableSection<Content: View, RowContent: View, Element: Hashable>: View {
    let header: Content
    let data: [Element]
    let rowContent: (Element) -> RowContent

    init(data: [Element], @ViewBuilder header: () -> Content, @ViewBuilder rowContent: @escaping (Element) -> RowContent) {
        self.header = header()
        self.data = data
        self.rowContent = rowContent
    }

    var body: some View {
        if !data.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6))

                ForEach(data.indices, id: \.self) { index in
                    TableRow(content: rowContent(data[index]), isLast: index == data.count - 1)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
    }
}

struct TableRow<Content: View>: View {
    let content: Content
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            content
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))

            if !isLast {
                Divider()
                    .background(Color(nsColor: .separatorColor))
            }
        }
        .clipShape(UnevenRoundedRectangle(
            bottomLeadingRadius: isLast ? 6 : 0,
            bottomTrailingRadius: isLast ? 6 : 0
        ))
    }
}
