//  
// ModelItemListItem.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/27/25.
//

import SwiftUI

struct ModelItemListItem: View {
    let item: Item
    let model: Model
    let index: Int

    var body: some View {
 // MARK: Item List Item

        HStack(spacing: 8) {
            Text("\(index + 1).")
                .foregroundColor(.secondary)
                .font(.footnote)

            ItemModelImage(item: item, model: model, size: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Available:")
                        .foregroundColor(.secondary)  
                        .font(.footnote)                      

                    Image(systemName: item.isAvailable ? SFSymbols.checkmarkCircleFill : SFSymbols.xmarkCircleFill)
                        .foregroundColor(item.isAvailable ? .green : .red)
                        .frame(16)
                        .font(.footnote)
                    }
                    
                if item.attention {
                    HStack(spacing: 6) {
                        Text("Attention:")
                            .foregroundColor(.secondary)  
                            .font(.footnote)   

                        Image(systemName: SFSymbols.exclamationmarkTriangleFill)
                            .foregroundColor(.yellow) 
                            .frame(16)                   
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}