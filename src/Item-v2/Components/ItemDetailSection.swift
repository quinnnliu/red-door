//
//  ItemDetailSection.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import SwiftUI

struct ItemDetailSection: View {
    let item: ItemV2
    let essentialsGroup: EssentialsGroup?

    @State private var showPurchaseInfo: Bool = false
    @State private var showDimensions: Bool = false

    init(item: ItemV2, essentialsGroup: EssentialsGroup? = nil) {
        self.item = item
        self.essentialsGroup = essentialsGroup
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if item.attention {
                AttentionBanner
            }

            DescriptionSection

            DetailsSection

            LocationRow

            if hasPurchaseInfo {
                PurchaseInfoSection
            }

            if let dimensions = item.dimensions {
                DimensionsSection(dimensions)
            }
            
            IdRow
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(Constants.CornerRadius.medium)
    }

    // MARK: Attention

    private var AttentionBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: SFSymbols.exclamationmarkTriangleFill)
                    .foregroundStyle(.orange)
                Text("Needs Attention")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.red)
            }

            if let description = item.attentionDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(Constants.CornerRadius.medium)
    }

    // MARK: Description

    private var DescriptionSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel("Description:")
            Text(item.description.isEmpty ? "No description" : item.description)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(item.description.isEmpty ? .secondary : .primary)
                .padding(8)
                .background(Color(.systemGray4))
                .cornerRadius(Constants.CornerRadius.medium)
        }
    }
    
    // MARK: IdRow
    private var IdRow: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("ID: ")
                .foregroundColor(.red)
                .bold()
            
            Text(viewModel.itemState.id)
                .font(.caption)
        }
    }

    // MARK: Type, Color, Material, Essential

    private var DetailsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel("Details:")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Type:")
                        .frame(width: labelWidth, alignment: .leading)
                    Spacer()
                    ValuePill {
                        Image(systemName: item.type.icon ?? SFSymbols.ellipsis)
                        Text(item.type.title)
                    }
                }

                if let color = item.color.color {
                    HStack {
                        Text("Color:")
                            .frame(width: labelWidth, alignment: .leading)
                        Spacer()
                        ValuePill {
                            Image(systemName: SFSymbols.circleFill)
                                .foregroundStyle(color)
                            Text(item.color.title)
                        }
                    }
                }

                HStack {
                    Text("Material:")
                        .frame(width: labelWidth, alignment: .leading)
                    Spacer()
                    ValuePill {
                        Text(item.material.title)
                    }
                }

                if let essentialsGroup {
                    HStack {
                        Text("Essential:")
                            .frame(width: labelWidth, alignment: .leading)
                        Spacer()
                        ValuePill {
                            Text("\(essentialsGroup.emoji) \(essentialsGroup.displayName)")
                        }
                    }
                }
                
            }
            .font(.callout)
            .padding(8)
            .background(Color(.systemGray4))
            .cornerRadius(Constants.CornerRadius.medium)
        }
    }

    // MARK: Location

    private var LocationRow: some View {
        HStack(spacing: .zero) {
            Text("Location:")
                .foregroundColor(.red)
                .bold()

            Spacer(minLength: .zero)

            SmallCTA(
                isButton: false,
                type: item.location.status.isAvailable ? .default : .red,
                size: .small,
                leadingIcon: item.location.status.icon,
                text: item.location.status.displayTitle,
                semibold: false
            )
        }
    }

    // MARK: Purchase Info

    private var hasPurchaseInfo: Bool {
        item.value != nil || item.brand != nil || item.purchaseLocation != nil || item.datePurchased != nil
    }

    private var PurchaseInfoSection: some View {
        CollapsibleSection(title: "Purchase Info:", isExpanded: $showPurchaseInfo) {
            if let value = item.value {
                InfoRow("Value ($):", String(format: "%.2f", value))
            }
            if let brand = item.brand {
                InfoRow("Brand:", brand)
            }
            if let location = item.purchaseLocation {
                InfoRow("Purchased At:", location)
            }
            if let date = item.datePurchased {
                InfoRow("Date:", date)
            }
        }
    }

    // MARK: Dimensions

    private func DimensionsSection(_ dimensions: ItemDimensions) -> some View {
        CollapsibleSection(title: "Dimensions:", isExpanded: $showDimensions) {
            if !dimensions.length.isEmpty {
                InfoRow("Length:", dimensions.length)
            }
            if !dimensions.width.isEmpty {
                InfoRow("Width:", dimensions.width)
            }
            if !dimensions.height.isEmpty {
                InfoRow("Height:", dimensions.height)
            }
            InfoRow("Unit:", dimensions.unit.rawValue.capitalized)
        }
    }

    // MARK: Helpers

    private let labelWidth: CGFloat = 110

    private func SectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.red)
            .bold()
    }

    private func InfoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .frame(width: labelWidth, alignment: .leading)
            Text(value)
        }
    }

    private func ValuePill<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 6) {
            content()
        }
        .padding(6)
        .background(Color(.systemGray4))
        .cornerRadius(Constants.CornerRadius.small)
    }

    private func CollapsibleSection<Content: View>(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(Constants.Animation.snappy) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    SectionLabel(title)

                    Spacer()

                    Image(systemName: isExpanded.wrappedValue ? SFSymbols.chevronUp : SFSymbols.chevronDown)
                }
            }

            if isExpanded.wrappedValue {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(.systemGray4))
                .cornerRadius(Constants.CornerRadius.medium)
            }
        }
    }
}
