//
//  EditRoomV2Sheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/1/26.
//

import SwiftUI

struct EditRoomV2Sheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var onSubmit: (_ name: String, _ squareFootage: String?) -> Void
    @State var currentRoomName: String
    @State var currentSquareFootage: String
    
    init(
        currentRoomName: String = "",
        currentSquareFootage: String? = nil,
        onSubmit: @escaping (_ name: String, _ squareFootage: String?) -> Void
    ) {
        self.onSubmit = onSubmit
        self._currentRoomName = State(initialValue: currentRoomName)
        self._currentSquareFootage = State(initialValue: currentSquareFootage ?? "")
    }
    
    // MARK: Body
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Room Name", text: $currentRoomName)
                .submitLabel(.done)
            
            TextField("Square Footage (optional)", text: $currentSquareFootage)
                .font(.caption2)
            
            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                Button {
                    onSubmit(currentRoomName, currentSquareFootage.trimmedOrNil)
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
        .presentationDetents([.fraction(0.25)])
    }
}
