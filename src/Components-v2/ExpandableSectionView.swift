//
//  ExpandableSectionView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/30/26.
//

import SwiftUI

enum ExpandableSectionStyle {
    case itemTypeGroup(type: ItemType, count: Int)
}

struct ExpandableSectionView<Content: View>: View {
    private let style: ExpandableSectionStyle
    @State private var isExpanded: Bool
    @ViewBuilder private let content: () -> Content

    init(
        style: ExpandableSectionStyle,
        isExpanded: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self._isExpanded = State(initialValue: isExpanded)
        self.content = content
    }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(Constants.Animation.snappy) {
                    isExpanded.toggle()
                }
            } label: {
                Header
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
            }
        }
    }
}

// MARK: - Header

private extension ExpandableSectionView {
    var Header: some View {
        switch style {
        case .itemTypeGroup(let type, let count):
            HStack(spacing: 8) {
                Image(systemName: type.icon ?? SFSymbols.ellipsis)
                Text(type.title)
                    .font(.headline)
                Spacer()
                Text("(\(count))")
                    .foregroundStyle(.secondary)
                Image(systemName: isExpanded ? SFSymbols.chevronUp : SFSymbols.chevronDown)
            }
            .padding(8)
            .background(Color(.systemGray5))
            .cornerRadius(Constants.CornerRadius.large)
        }
    }
}
