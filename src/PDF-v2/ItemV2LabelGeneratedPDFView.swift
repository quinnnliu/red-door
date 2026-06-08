//
//  ItemV2LabelGeneratedPDFView.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/22/25.
//

import SwiftUI

struct ItemV2LabelGeneratedPDFView: View {
    // MARK: Init Values
    
    let item: ItemV2
    let qrCodeImage: UIImage?
    let itemImage: UIImage?
    
    // MARK: Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Name: \(item.displayName)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.red)
            
            HStack(spacing: 20) {
                if let qrCodeImage = qrCodeImage {
                    Image(uiImage: qrCodeImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                } else {
                    Text("Error Generating QR Code")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .frame(width: 200, height: 200)
                }
                
                // Item Image
                if let itemImage = itemImage {
                    Image(uiImage: itemImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .foregroundColor(Color(.systemGray5))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: SFSymbols.photoBadgePlus)
                                .font(.system(size: 40))
                                .bold()
                                .foregroundColor(.secondary)
                        )
                }
            }
            
                // Description
            VStack(alignment: .leading, spacing: 4) {
                Text("Description:")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(item.description)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(40)
        .background(Color.white)
    }
}
