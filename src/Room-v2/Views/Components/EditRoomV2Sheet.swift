//
//  EditRoomV2Sheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/1/26.
//

import SwiftUI

struct EditRoomV2Sheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var onSubmit: (String) -> Void
    @State var currentRoomName: String
    
    init(currentRoomName: String = "", onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
        self._currentRoomName = State(initialValue: currentRoomName)
    }
    
    // MARK: Body
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Room Name", text: $currentRoomName)
                .submitLabel(.done)
            
            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                Button {
                    onSubmit(currentRoomName)
                    dismiss()
                } label: {
                    Text("Save")
                        .fontWeight(.semibold)
                }
            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameVerticalPadding()
        .presentationDetents([.fraction(0.125)])
    }
}
