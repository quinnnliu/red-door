//
//  EditPullListSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/1/26.
//

import SwiftUI

struct EditPullListSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: EditPullListViewModel
    @State private var showAddressSheet: Bool = false

    init(viewModel: EditPullListViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    AddressButton

                    PrimaryImageEditor(image: viewModel.draft.image) { result in
                        handleImageAction(result)
                    }

                    DatePicker(
                        selection: $viewModel.draft.installDate,
                        displayedComponents: [.date]
                    ) {
                        Text("Install Date:")
                            .foregroundColor(.secondary)
                            .bold()
                    }

                    DatePicker(
                        selection: $viewModel.draft.uninstallDate,
                        displayedComponents: [.date]
                    ) {
                        Text("Uninstall Date:")
                            .foregroundColor(.red)
                            .bold()
                    }

                    HStack {
                        Text("Client:")
                        TextField("", text: $viewModel.draft.clientId)
                            .padding(6)
                            .background(Color(.systemGray5))
                            .cornerRadius(Constants.CornerRadius.medium)
                    }

                    HStack {
                        Text("Square Feet:")
                        TextField("Optional", text: Binding(
                            get: { viewModel.draft.squareFootage ?? "" },
                            set: { viewModel.draft.squareFootage = $0.isEmpty ? nil : $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .padding(6)
                        .background(Color(.systemGray5))
                        .cornerRadius(Constants.CornerRadius.medium)
                    }

                    Footer
                }
                .frameHorizontalPadding()
                .frameVerticalPadding()
            }
            .alert(viewModel.alertText, isPresented: $viewModel.showAlert) {
                Button("Ok", role: .cancel) {}
            }
            .sheet(isPresented: $showAddressSheet) {
                AddressSheet(selectedAddress: $viewModel.draft.address, addressId: $viewModel.draft.addressId)
            }

            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Saving Pull List...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            }
        }
    }

    // MARK: AddressButton

    private var AddressButton: some View {
        RDButton(
            style: .outline,
            size: .default,
            leadingIcon: SFSymbols.mapPinAndEllipse,
            label: viewModel.draft.address.isInitialized() ? viewModel.draft.address.getStreetAddress() ?? "" : "Enter Address"
        ) {
            showAddressSheet = true
        }
    }

    // MARK: Footer

    private var Footer: some View {
        HStack(spacing: 12) {
            RDButton(style: .outline, size: .default, label: "Cancel", fullWidth: true) {
                dismiss()
            }

            RDButton(style: .red, size: .default, label: "Save", fullWidth: true) {
                Task {
                    if await viewModel.save() { dismiss() }
                }
            }
            .disabled(!viewModel.canSave || viewModel.isLoading)
        }
        .padding(.top, 8)
    }
}

private extension EditPullListSheet {
    func handleImageAction(_ actionArgument: Any?) {
        guard let action = actionArgument as? ImageEditorAction else { return }
        switch action {
        case .newImage(let image):
            viewModel.draft.image = image
        case .deleteImage:
            // Storage is only touched on Save, so Cancel leaves it alone.
            viewModel.draft.image = nil
        }
    }
}
