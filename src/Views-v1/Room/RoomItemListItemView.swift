// //
// //  RoomItemListItemView.swift
// //  RedDoor
// //
// //  Created by Quinn Liu on 2/23/25.
// //

// import SwiftUI
// import CachedAsyncImage

// struct RoomItemListItemView: View {
//     let item: Item
//     let image: RDImage

//     var body: some View {
//         HStack(alignment: .center,spacing: 0) {
//             ItemImage()

//             VStack(alignment: .leading, spacing: 4) {
//                 Text(item.name)
//                 Text("•")
//                 Image(systemName: Model.typeMap[item.model?.type ?? ""] ?? "nosign")
//                 Text("•")
//                 Image(systemName: SFSymbols.circleFill)
//                     .foregroundColor(Model.colorMap[item.model?.primaryColor ?? ""] ?? .black)
//             }
//         }
//     }

//     @ViewBuilder
//     private func ItemImage() -> some View {
//         if let imageURL = image.imageURL {
//             CachedAsyncImage(url: imageURL) { image in
//                 image
//                     .resizable()
//                     .scaledToFill()
//                     .frame(width: 40, height: 40)
//                     .cornerRadius(4)
//             } placeholder: {
//                 Color.gray
//                     .overlay(Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
//                         .foregroundColor(.white))
//             }
//         }
//     }
// }