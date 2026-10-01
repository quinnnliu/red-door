//
//  EditItemDetailSection.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/26/26.
//

import SwiftUI

struct EditItemDetailSection: View {
    @Binding var description: String
    @Binding var color: ItemColor
    @Binding var material: ItemMaterial
    @Binding var type: ItemType
    @Binding var value: Double?
    @Binding var brand: String?
    @Binding var purchaseLocation: String?
    @Binding var datePurchased: String?
    @State private var showPurchaseInfoSection: Bool = true

    @State private var isColorPickerActive = false
    @State private var isMaterialPickerActive = false
    @State private var isTypePickerActive = false
    
    @Binding var dimensions: ItemDimensions?
    @State private var showDimensionsSection: Bool = true

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                SectionTitle("Description:")
                
                TextField("A brief description about these items...", text: $description)
                    .font(.footnote)
                    .lineLimit(2...5)
                    .submitLabel(.done)
                    .disabled(description.count > 100)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(Constants.CornerRadius.medium)
            }

            ColorMaterialRow

            TypeRow
            
            PurchaseInfoSection
            
            DimensionsSection
        }
        
    }

    // MARK: ColorMaterialRow
    private var ColorMaterialRow: some View {
        HStack(alignment: .center, spacing: 8) {
            if !isMaterialPickerActive {
                VStack(alignment: .leading, spacing: 4) {
                    ColorPickerToggleV2(
                        isActive: $isColorPickerActive,
                        selectedColor: color
                    )
                    
                    if isColorPickerActive {
                        EnumGridPicker(
                            selectedItem: $color,
                            isActive: $isColorPickerActive,
                            items: ItemColor.allCases,
                            label: { $0.title },
                            color: { $0.color },
                            icon: { $0.icon }
                        )
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(Constants.CornerRadius.medium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if !isColorPickerActive {
                VStack(alignment: .leading, spacing: 4) {
                    MaterialPickerToggleV2(
                        isActive: $isMaterialPickerActive,
                        selectedMaterial: material
                    )
                    
                    if isMaterialPickerActive {
                        EnumGridPicker(
                            selectedItem: $material,
                            isActive: $isMaterialPickerActive,
                            items: ItemMaterial.allCases,
                            label: { $0.title },
                            color: { _ in nil },
                            icon: { _ in nil }
                        )
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(Constants.CornerRadius.medium)
                        
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: Type Row

    private var TypeRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(Constants.Animation.snappy) {
                    isTypePickerActive.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Type:")
                        .foregroundColor(.red)
                        .bold()

                    Spacer(minLength: .zero)
                    HStack {
                        if let icon = type.icon {
                            Image(systemName: icon)
                        }
                        Text(type.title)
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color(.systemGray4))
                    .cornerRadius(Constants.CornerRadius.small)
                }
            }

            if isTypePickerActive {
                EnumGridPicker(
                    selectedItem: $type,
                    isActive: $isTypePickerActive,
                    items: ItemType.allCases,
                    label: { $0.title },
                    color: { $0.color },
                    icon: { $0.icon }
                )
            }
        }
    }

    // MARK: PurchaseInfoSection

    var PurchaseInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(Constants.Animation.snappy) {
                    showPurchaseInfoSection.toggle()
                }
            } label: {
                HStack {
                    SectionTitle("Purchase Info:")

                    Spacer()
                    
                    Image(systemName: showPurchaseInfoSection ? SFSymbols.chevronUp : SFSymbols.chevronDown)
                }
            }

            if showPurchaseInfoSection {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Value ($):")
                            .frame(width: 110, alignment: .leading)
                        TextField("0.00 (optional)", value: $value, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Brand:")
                            .frame(width: 110, alignment: .leading)
                        TextField("Brand (optional)", text: Binding(
                            get: { brand ?? "" },
                            set: { brand = $0.isEmpty ? nil : $0 }
                        ))
                    }
                    
                    HStack {
                        Text("Purchased At:")
                            .frame(width: 110, alignment: .leading)
                        TextField("Store or URL (optional)", text: Binding(
                            get: { purchaseLocation ?? "" },
                            set: { purchaseLocation = $0.isEmpty ? nil : $0 }
                        ))
                    }
                    
                    HStack {
                        Text("Date:")
                            .frame(width: 110, alignment: .leading)
                        if datePurchased != nil {
                            DatePicker("", selection: datePickerBinding, displayedComponents: .date)
                                .labelsHidden()
                            Button {
                                datePurchased = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button("Add date") {
                                datePurchased = Self.dateFormatter.string(from: Date())
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .font(.caption)
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(Constants.CornerRadius.medium)
            }
        }

    }

    // MARK: DimensionsSection
    
    var DimensionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            Button {
                withAnimation(Constants.Animation.snappy) {
                    showDimensionsSection.toggle()
                }
            } label: {
                HStack {
                    SectionTitle("Dimensions:")

                    Spacer()
                    
                    Image(systemName: showDimensionsSection ? SFSymbols.chevronUp : SFSymbols.chevronDown)
                }
            }
            
            if showDimensionsSection {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Length:")
                            .frame(width: 110, alignment: .leading)
                        TextField("0 (optional)", text: dimensionsBinding.length)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Width:")
                            .frame(width: 110, alignment: .leading)
                        TextField("0 (optional)", text: dimensionsBinding.width)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Height:")
                            .frame(width: 110, alignment: .leading)
                        TextField("0 (optional)", text: dimensionsBinding.height)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Unit:")
                            .frame(width: 110, alignment: .leading)
                        Picker("Unit", selection: dimensionsBinding.unit) {
                            ForEach(ItemDimensions.UnitType.allCases, id: \.self) { unit in
                                Text(unit.rawValue.capitalized)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .font(.caption)
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(Constants.CornerRadius.medium)
            }
        }
    }
    
    // MARK: Section Title
    
    func SectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.red)
            .bold()
    }
    
    // MARK: MaterialPickerToggle
    
    func MaterialPickerToggleV2(
        isActive: Binding<Bool>,
        selectedMaterial: ItemMaterial
    ) -> some View {
        Button {
            withAnimation(Constants.Animation.snappy) {
                isActive.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                SectionTitle("Material:")
                
                Text(selectedMaterial.title)
                    .frame(maxWidth: .infinity)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(Color(.systemGray4))
                    .cornerRadius(Constants.CornerRadius.small)
            }
        }
    }

    // MARK: ColorPickerToggle
    
    func ColorPickerToggleV2(
        isActive: Binding<Bool>,
        selectedColor: ItemColor
    ) -> some View {
        Button {
            withAnimation(Constants.Animation.snappy) {
                isActive.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                SectionTitle("Color:")
                
                Text(selectedColor.title)
                    .frame(maxWidth: .infinity)
                    .font(.caption2)
                    .foregroundColor(selectedColor.color == .white || selectedColor.color == .clear ? .black : .white)
                    .padding(8)
                    .background(selectedColor.color)
                    .cornerRadius(Constants.CornerRadius.small)
            }
        }
    }
    
    // MARK: Date Purchased Binding

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        return f
    }()

    private var datePickerBinding: Binding<Date> {
        Binding(
            get: {
                guard let str = datePurchased else { return Date() }
                return Self.dateFormatter.date(from: str) ?? Date()
            },
            set: { datePurchased = Self.dateFormatter.string(from: $0) }
        )
    }
    
    // MARK: Dimensions Binding
    private var dimensionsBinding: Binding<ItemDimensions> {
        Binding(
            get: {
                guard let dimensions = dimensions else { return ItemDimensions(length: "0", width: "0", height: "0", unit: .imperial) }
                return dimensions
            },
            set: { newDimensions in
                dimensions = newDimensions
            }
        )
    }
}
