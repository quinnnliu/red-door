//
//  EditModelAttributesSection.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/26/26.
//

import SwiftUI

struct EditItemAttributesSection: View {
    @Binding var description: String
    @Binding var color: ItemColor
    @Binding var material: ItemMaterial
    @Binding var type: ItemType
    @Binding var isEssential: Bool
    @Binding var value: Double?
    @Binding var brand: String?
    @Binding var purchaseLocation: String?
    @Binding var datePurchased: String?

    @State private var isColorPickerActive = false
    @State private var isMaterialPickerActive = false

    @FocusState private var focusDescription: Bool

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: Description

            VStack(alignment: .leading, spacing: 4) {
                SectionTitle("Description:")

                TextField("Add a brief description about these items...", text: $description, axis: .vertical)
                    .lineLimit(2...5)
                    .focused($focusDescription)
                    .submitLabel(.done)
                    .onSubmit { focusDescription = false }
                    .disabled(description.count > 100)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }

            // MARK: Color + Material

            ColorMaterialRow

            // MARK: Details

            VStack(alignment: .leading, spacing: 4) {
                SectionTitle("Details:")

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 0) {
                        HStack(alignment: .center, spacing: 4) {
                            Text("Type:")

                            Picker("", selection: $type) {
                                ForEach(ItemType.allCases, id: \.self) { option in
                                    Text(option.rawValue)
                                        .tag(option)
                                }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        HStack(alignment: .center, spacing: 4) {
                            Text("Essential:")
                                .foregroundColor(.red)
                                .bold()

                            Toggle("", isOn: $isEssential)
                                .labelsHidden()
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }

            // MARK: Purchase Info

            VStack(alignment: .leading, spacing: 4) {
                SectionTitle("Purchase Info:")

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Value ($):")
                            .frame(width: 110, alignment: .leading)
                        TextField("0.00", value: $value, format: .number)
                            .keyboardType(.decimalPad)
                    }

                    HStack {
                        Text("Brand:")
                            .frame(width: 110, alignment: .leading)
                        TextField("Brand", text: Binding(
                            get: { brand ?? "" },
                            set: { brand = $0.isEmpty ? nil : $0 }
                        ))
                    }

                    HStack {
                        Text("Purchased At:")
                            .frame(width: 110, alignment: .leading)
                        TextField("Store or URL", text: Binding(
                            get: { purchaseLocation ?? "" },
                            set: { purchaseLocation = $0.isEmpty ? nil : $0 }
                        ))
                    }

                    HStack {
                        Text("Date:")
                            .frame(width: 110, alignment: .leading)
                        TextField("MM/DD/YYYY", text: datePurchasedBinding)
                        .keyboardType(.numberPad)
                    }
                }
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
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
                            color: { $0.color }
                        )
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
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
                            color: { _ in nil }
                        )
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: Section Title
    func SectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .foregroundStyle(.red)
            .bold()
    }
        // MARK: MaterialPickerToggle
    
    @ViewBuilder
    func MaterialPickerToggleV2(
        isActive: Binding<Bool>,
        selectedMaterial: ItemMaterial
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isActive.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                SectionTitle("Material:")
                
                Text(selectedMaterial.title)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(isActive.wrappedValue ? Color.clear : Color(.systemGray4))
                    .cornerRadius(6)
            }
        }
    }

    // MARK: ColorPickerToggle
    
    @ViewBuilder
    func ColorPickerToggleV2(
        isActive: Binding<Bool>,
        selectedColor: ItemColor
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isActive.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                SectionTitle("Color:")
                
                Image(systemName: SFSymbols.circleFill)
                    .foregroundStyle(selectedColor.color)
                    .padding(8)
                    .background(isActive.wrappedValue ? Color.clear : Color(.systemGray4))
                    .cornerRadius(6)
            }
        }
    }
    
    // MARK: Date Purchased Binding
    
    private var datePurchasedBinding: Binding<String> {
        Binding(
            get: { datePurchased ?? "" },
            set: { newValue in
                let digits = newValue.filter { $0.isNumber }
                let limited = String(digits.prefix(8))
                var formatted = ""
                for (i, char) in limited.enumerated() {
                    if i == 2 || i == 4 { formatted += "/" }
                    formatted.append(char)
                }
                datePurchased = formatted.isEmpty ? nil : formatted
            }
        )
    }
}
