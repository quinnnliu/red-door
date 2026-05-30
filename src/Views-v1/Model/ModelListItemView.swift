//
//  ModelListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 2/16/25.
//

import CachedAsyncImage
import SwiftUI

struct ModelListItemView: View {
    var model: Model
    let imageWidth: CGFloat = Constants.screenWidth / 7
    
    private var typeIconName: String {
        // Handle "Miscellaneous" -> "Misc" mapping
        let lookupType = model.type == "Miscellaneous" ? "Misc" : model.type
        return Model.typeMap[lookupType] ?? "camera.metering.unknown"
    }

    // MARK: Body
    var body: some View {
        HStack(spacing: 12) {
            ModelImage()
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Count: \(model.itemIds.count)")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                
                HStack(spacing: 4) {
                    // Type icon
                    Image(systemName: typeIconName)
                        .font(.footnote)
                        .foregroundColor(.primary)
                    
                    Text("•")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    // Primary material
                    Text(model.primaryMaterial)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    // Color icon
                    Image(systemName: SFSymbols.circleFill)
                        .font(.footnote)
                        .foregroundStyle(Model.colorMap[model.primaryColor] ?? .black)

                    Text("•")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    // Available item count
                    HStack(spacing: 0) {
                        Text("Available: ")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text("\(model.availableItemCount)")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()

            if model.isEssential {
                Image(systemName: SFSymbols.starCircleFill)
                    .foregroundColor(.yellow)
                    .padding(.trailing, 6)
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }


    // MARK: Model Image
    @ViewBuilder 
    private func ModelImage() -> some View {
        if let imageURL = model.primaryImage.imageURL {
            CachedAsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(imageWidth)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(imageWidth)
                        .cornerRadius(6)
                case .failure:
                    Image(systemName: SFSymbols.photoBadgePlus)
                        .frame(imageWidth)
                        .foregroundColor(.secondary)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(systemName: SFSymbols.photo)
                .frame(width: 60, height: 60)
                .foregroundColor(.secondary)
        }
    }
}

// #Preview {
//    ModelListItemView(model: Model())
// }
