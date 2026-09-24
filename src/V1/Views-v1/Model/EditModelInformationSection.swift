//
//  EditModelInformationSection.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/21/24.
//

import SwiftUI

struct EditModelInformationSection: View {
    @Binding var viewModel: ModelViewModel

    @State private var isPrimaryColorPickerActive = false
    @State private var isSecondaryColorPickerActive = false
    @State private var isPrimaryMaterialPickerActive = false
    @State private var isSecondaryMaterialPickerActive = false

    @FocusState private var focusDescription: Bool

    let initialItemCount: Int

    init(viewModel: Binding<ModelViewModel>) {
        _viewModel = viewModel
        self.initialItemCount = max(viewModel.wrappedValue.selectedModel.itemIds.count, 1)
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Description:")
                    .foregroundColor(.red)
                    .bold()
                    
                TextField("Type here", text: $viewModel.selectedModel.description)
                    .focused($focusDescription)
                    .submitLabel(.done)
                    .onSubmit {
                        focusDescription = false
                    }
                    .disabled(viewModel.selectedModel.description.count > 100)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Colors:")
                    .foregroundColor(.red)
                    .bold()

                ColorPickerRow()
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Materials:")
                    .foregroundColor(.red)
                    .bold()

                MaterialPickerRow()
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Details:")
                    .foregroundColor(.red)
                    .bold()

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 0) {
                        HStack(alignment: .center, spacing: 4) {
                            Text("Type:")

                            Picker("", selection: $viewModel.selectedModel.type) {
                                ForEach(Array(Model.typeMap), id: \.key) { option, iconName in
                                    HStack(spacing: 8) {
                                        Text(option)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Image(systemName: iconName)
                                            .padding(4)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(6)
                                    }
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
                            
                            Toggle("", isOn: $viewModel.selectedModel.isEssential)
                                .labelsHidden()
                        }
                    }

                    // can only increase the # of items, delete items shouldn't be when editing (min of 1) 
                    Stepper(value: $viewModel.itemCount, in: initialItemCount...100, step: 1) {
                        Text("Item Count: \(viewModel.itemCount)")
                    }
                }
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
    }

    // MARK: ColorPickerRow

    @ViewBuilder
    private func ColorPickerRow() -> some View {
        HStack(alignment: .top, spacing: 0) {
            if !isSecondaryColorPickerActive {
                VStack(alignment: .leading, spacing: 4) {
                    ColorPickerToggle(
                        isActive: $isPrimaryColorPickerActive,
                        title: "Primary:",
                        selectedColor: viewModel.selectedModel.primaryColor
                    )

                    if isPrimaryColorPickerActive {
                        GridPicker(
                            selectedItem: $viewModel.selectedModel.primaryColor,
                            isActive: $isPrimaryColorPickerActive,
                            title: "Primary:",
                            items: Array(Model.colorMap.keys)
                        )
                    }
                }
            }

            Spacer()
            
            if !isPrimaryColorPickerActive {
                VStack(alignment: .leading, spacing: 4) {
                    ColorPickerToggle(
                        isActive: $isSecondaryColorPickerActive,
                        title: "Secondary: ",
                        selectedColor: viewModel.selectedModel.secondaryColor
                    )

                    if isSecondaryColorPickerActive {
                        GridPicker(
                            selectedItem: $viewModel.selectedModel.secondaryColor,
                            isActive: $isSecondaryColorPickerActive,
                            title: "Secondary:",
                            items: Array(Model.colorMap.keys)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: MaterialPickerRow
    
    @ViewBuilder
    private func MaterialPickerRow() -> some View {
        HStack(alignment: .top, spacing: 0) {
            if !isSecondaryMaterialPickerActive {
                VStack(alignment: .leading, spacing: 4) {
                    MaterialPickerToggle(
                        isActive: $isPrimaryMaterialPickerActive,
                        title: "Primary:",
                        selectedMaterial: viewModel.selectedModel.primaryMaterial
                    )

                    if isPrimaryMaterialPickerActive {
                        GridPicker(
                            selectedItem: $viewModel.selectedModel.primaryMaterial,
                            isActive: $isPrimaryMaterialPickerActive,
                            title: "Primary:",
                            items: Model.materialOptions
                        )
                    }
                }
            }

            Spacer()
            
            if !isPrimaryMaterialPickerActive {
                VStack(alignment: .leading, spacing: 4) {
                    MaterialPickerToggle(
                        isActive: $isSecondaryMaterialPickerActive,
                        title: "Secondary:",
                        selectedMaterial: viewModel.selectedModel.secondaryMaterial
                    )

                    if isSecondaryMaterialPickerActive {
                        GridPicker(
                            selectedItem: $viewModel.selectedModel.secondaryMaterial,
                            isActive: $isSecondaryMaterialPickerActive,
                            title: "Secondary:",
                            items: Model.materialOptions
                        )
                    }
                }
            }
        }
    }
}

// MARK: MaterialPickerToggle

struct MaterialPickerToggle: View {
    @Binding var isActive: Bool
    var title: String
    var selectedMaterial: String

    var body: some View {
        // Button to show/hide picker
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isActive.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Text(title)
                    .foregroundColor(.primary)

                Text(selectedMaterial)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(isActive ? Color.clear : Color(.systemGray4) )
                    .cornerRadius(6)
            }
        }
    }
}

// MARK: ColorPickerToggle

struct ColorPickerToggle: View {
    @Binding var isActive: Bool
    var title: String
    var selectedColor: String

    var body: some View {
        // Button to show/hide picker
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isActive.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Text(title)
                    .foregroundColor(.primary)

                Image(systemName: SFSymbols.circleFill)
                    .foregroundStyle(Model.colorMap[selectedColor] ?? .black)
                    .padding(8)
                    .background(isActive ? Color.clear : Color(.systemGray4))
                    .cornerRadius(6)
            }
        }
    }
}


