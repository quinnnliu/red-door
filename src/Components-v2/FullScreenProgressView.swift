//
//  FullScreenProgressView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/30/26.
//

import SwiftUI

struct FullScreenProgressView: View {
    
    let label: String
    
    init(label: String) {
        self.label = label
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            ProgressView(label)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .shadow(radius: 10)
        }
    }
}
