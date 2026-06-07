//
//  InstallPullListSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/6/26.
//

import SwiftUI

struct InstallPullListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: InstallPullListSheetViewModel

    init(list: PullListV2) {
        viewModel = InstallPullListSheetViewModel(from: list)
    }

    var body: some View {
        VStack(spacing: .zero) {
            TopBar
            
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
        .frameTop()
        .frameHorizontalPadding()
        .onAppear {
            viewModel.startListening()
        }
        .alert(viewModel.alertText, isPresented: $viewModel.showAlert) {
            Button("Ok", role: .cancel) {}
        }
    }
}

extension InstallPullListSheet {
    
    // MARK: TopBar
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton(action: {
                    Task {
                        await viewModel.clearInstallingSession()
                    }
                })
            },
            header: {
                Text("Installing: \(viewModel.pullListState.address.getStreetAddress() ?? "loading")")
            },
            trailingView: {
                EmptyTopBarIconButton()
            }
        )
    }
    
    // MARK: 
}
