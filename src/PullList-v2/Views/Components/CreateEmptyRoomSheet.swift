//
//  CreateEmptyRoomSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import SwiftUI

struct CreateEmptyRoomSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @FocusState var keyboardFocused: Bool
    @State private var newRoomName: String = ""
    @State private var existingRoomAlert: Bool = false
    var action: (Any?) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Room Name", text: $newRoomName)
                .focused($keyboardFocused)
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
                    action(CreateEmptyRoomAction.createEmptyRoom(newRoomName: newRoomName))
                } label: {
                    Text("Add Room")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
        }
        
        .frameTop()
        .padding(24)
        .presentationDetents([.fraction(0.125)])
    }
}

enum CreateEmptyRoomAction {
    case createEmptyRoom(newRoomName: String)
}

//#Preview {
//    CreateEmptyRoomSheet()
//}
