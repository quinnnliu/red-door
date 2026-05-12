////
////  EditModelAttributesSection.swift
////  RedDoor
////
////  Created by Quinn Liu on 4/26/26.
////
//
//import SwiftUI
//
//struct EditModelAttributesSection: View {
//    @Binding var description: String
//    @Binding var color: ModelColor
//    @Binding var material: ModelMaterial
//    @Binding var type: ModelTypeV2
//    @Binding var isEssential: Bool
//    @Binding var value: Double?
//    @Binding var brand: String?
//    @Binding var purchaseLocation: String?
//    @Binding var datePurchased: String?
//
//    @State private var isColorPickerActive = false
//    @State private var isMaterialPickerActive = false
//
//    @FocusState private var focusDescription: Bool
//
//    // MARK: Body
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//
//            // MARK: Description
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Description:")
//                    .foregroundColor(.red)
//                    .bold()
//
//                TextField("Type here", text: $description)
//                    .focused($focusDescription)
//                    .submitLabel(.done)
//                    .onSubmit { focusDescription = false }
//                    .disabled(description.count > 100)
//                    .padding(8)
//                    .background(Color(.systemGray5))
//                    .cornerRadius(8)
//            }
//
//            // MARK: Color + Material
//
//            ColorMaterialRow
//
//            // MARK: Details
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Details:")
//                    .foregroundColor(.red)
//                    .bold()
//
//                VStack(alignment: .leading, spacing: 4) {
//                    HStack(alignment: .center, spacing: 0) {
//                        HStack(alignment: .center, spacing: 4) {
//                            Text("Type:")
//
//                            Picker("", selection: $type) {
//                                ForEach(ModelTypeV2.allCases, id: \.self) { option in
//                                    Text(option.rawValue)
//                                        .tag(option)
//                                }
//                            }
//                            .fixedSize(horizontal: false, vertical: true)
//                        }
//                        .frame(maxWidth: .infinity, alignment: .leading)
//
//                        Spacer()
//
//                        HStack(alignment: .center, spacing: 4) {
//                            Text("Essential:")
//                                .foregroundColor(.red)
//                                .bold()
//
//                            Toggle("", isOn: $isEssential)
//                                .labelsHidden()
//                        }
//                    }
//                }
//                .padding(8)
//                .background(Color(.systemGray5))
//                .cornerRadius(8)
//            }
//
//            // MARK: Purchase Info
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Purchase Info:")
//                    .foregroundColor(.red)
//                    .bold()
//
//                VStack(alignment: .leading, spacing: 8) {
//                    HStack {
//                        Text("Value ($):")
//                            .frame(width: 110, alignment: .leading)
//                        TextField("0.00", value: $value, format: .number)
//                            .keyboardType(.decimalPad)
//                    }
//
//                    HStack {
//                        Text("Brand:")
//                            .frame(width: 110, alignment: .leading)
//                        TextField("Brand", text: Binding(
//                            get: { brand ?? "" },
//                            set: { brand = $0.isEmpty ? nil : $0 }
//                        ))
//                    }
//
//                    HStack {
//                        Text("Purchased At:")
//                            .frame(width: 110, alignment: .leading)
//                        TextField("Store or URL", text: Binding(
//                            get: { purchaseLocation ?? "" },
//                            set: { purchaseLocation = $0.isEmpty ? nil : $0 }
//                        ))
//                    }
//
//                    HStack {
//                        Text("Date:")
//                            .frame(width: 110, alignment: .leading)
//                        TextField("MM/DD/YYYY", text: Binding(
//                            get: { datePurchased ?? "" },
//                            set: { datePurchased = $0.isEmpty ? nil : $0 }
//                        ))
//                        .keyboardType(.numbersAndPunctuation)
//                    }
//                }
//                .padding(8)
//                .background(Color(.systemGray5))
//                .cornerRadius(8)
//            }
//        }
//    }
//
//    // MARK: ColorMaterialRow
//    private var ColorMaterialRow: some View {
//        HStack(alignment: .top, spacing: 12) {
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Color:")
//                    .foregroundColor(.red)
//                    .bold()
//
//                VStack(alignment: .leading, spacing: 4) {
//                    ColorPickerToggleV2(
//                        isActive: $isColorPickerActive,
//                        title: "Color:",
//                        selectedColor: color
//                    )
//
//                    if isColorPickerActive {
//                        EnumGridPicker(
//                            selectedItem: $color,
//                            isActive: $isColorPickerActive,
//                            items: ModelColor.allCases,
//                            label: { $0.title },
//                            color: { $0.color }
//                        )
//                    }
//                }
//                .padding(8)
//                .background(Color(.systemGray5))
//                .cornerRadius(8)
//            }
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Material:")
//                    .foregroundColor(.red)
//                    .bold()
//
//                VStack(alignment: .leading, spacing: 4) {
//                    MaterialPickerToggleV2(
//                        isActive: $isMaterialPickerActive,
//                        title: "Material:",
//                        selectedMaterial: material
//                    )
//
//                    if isMaterialPickerActive {
//                        EnumGridPicker(
//                            selectedItem: $material,
//                            isActive: $isMaterialPickerActive,
//                            items: ModelMaterial.allCases,
//                            label: { $0.title },
//                            color: { _ in nil }
//                        )
//                    }
//                }
//                .padding(8)
//                .background(Color(.systemGray5))
//                .cornerRadius(8)
//            }
//        }
//    }
//}
//
//// MARK: EnumGridPicker
//
//private struct EnumGridPicker<T: Hashable>: View {
//    @Binding var selectedItem: T
//    @Binding var isActive: Bool
//    let items: [T]
//    let label: (T) -> String
//    let color: (T) -> Color?
//
//    private let columns = Array(repeating: GridItem(.flexible()), count: 6)
//
//    var body: some View {
//        LazyVGrid(columns: columns, spacing: 6) {
//            ForEach(items, id: \.self) { item in
//                Button {
//                    selectedItem = item
//                    withAnimation(.spring(response: 0.3)) {
//                        isActive = false
//                    }
//                } label: {
//                    VStack(spacing: 2) {
//                        if let itemColor = color(item) {
//                            Image(systemName: SFSymbols.circleFill)
//                                .font(.system(size: 16))
//                                .foregroundStyle(itemColor)
//                                .overlay(
//                                    Circle()
//                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//                                        .padding(2)
//                                )
//                        }
//
//                        Text(label(item))
//                            .font(.system(size: 10))
//                            .foregroundColor(.primary)
//                            .lineLimit(1)
//                            .minimumScaleFactor(0.7)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 6)
//                    .background(
//                        RoundedRectangle(cornerRadius: 6)
//                            .fill(selectedItem == item ? Color.blue.opacity(0.1) : Color.clear)
//                    )
//                }
//                .buttonStyle(.plain)
//            }
//        }
//        .padding(8)
//        .transition(.opacity.combined(with: .move(edge: .top)))
//        .overlay(
//            RoundedRectangle(cornerRadius: 8)
//                .stroke(Color(.systemGray5), lineWidth: 2)
//        )
//    }
//}
//
//// MARK: MaterialPickerToggle
//
//struct MaterialPickerToggleV2: View {
//    @Binding var isActive: Bool
//    var title: String
//    var selectedMaterial: ModelMaterial
//
//    var body: some View {
//        Button(action: {
//            withAnimation(.spring(response: 0.3)) {
//                isActive.toggle()
//            }
//        }) {
//            HStack(spacing: 6) {
//                Text(title)
//                    .foregroundColor(.primary)
//
//                Text(selectedMaterial.title)
//                    .font(.caption2)
//                    .foregroundColor(.blue)
//                    .padding(8)
//                    .background(isActive ? Color.clear : Color(.systemGray4))
//                    .cornerRadius(6)
//            }
//        }
//    }
//}
//
//// MARK: ColorPickerToggle
//
//struct ColorPickerToggleV2: View {
//    @Binding var isActive: Bool
//    var title: String
//    var selectedColor: ModelColor
//
//    var body: some View {
//        Button(action: {
//            withAnimation(.spring(response: 0.3)) {
//                isActive.toggle()
//            }
//        }) {
//            HStack(spacing: 6) {
//                Text(title)
//                    .foregroundColor(.primary)
//
//                Image(systemName: SFSymbols.circleFill)
//                    .foregroundStyle(selectedColor.color)
//                    .padding(8)
//                    .background(isActive ? Color.clear : Color(.systemGray4))
//                    .cornerRadius(6)
//            }
//        }
//    }
//}
