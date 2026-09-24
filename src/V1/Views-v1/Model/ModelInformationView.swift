//
//  ModelInformationView.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/21/24.
//

import SwiftUI

struct ModelInformationView: View {
    let model: Model

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {

                // MARK: Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description:")
                        .foregroundColor(.red)
                        .bold()
                        
                    Text(model.description.isEmpty ? "No description" : model.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(model.description.isEmpty ? .secondary : .primary)
                        .padding(8)
                        .background(Color(.systemGray4))
                        .cornerRadius(8)
                }

                // MARK: Colors
                Text("Colors:")
                    .foregroundColor(.red)
                    .bold()

                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 0) {
                            Text("Primary: ")
                                .foregroundColor(.primary)

                            Image(systemName: SFSymbols.circleFill)
                                .foregroundColor(Model.colorMap[model.primaryColor] ?? .black)
                                .padding(8)
                                .background(Color(.systemGray4))
                                .cornerRadius(6)
                        }
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Secondary:")
                                .foregroundColor(.primary)

                            Image(systemName: SFSymbols.circleFill)
                                .foregroundColor(Model.colorMap[model.secondaryColor] ?? .black)
                                .padding(8)
                                .background(Color(.systemGray4))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray4))
                .cornerRadius(8)
            }


            // MARK: Materials
            VStack(alignment: .leading, spacing: 4) {
                Text("Materials:")
                    .foregroundColor(.red)
                    .bold()

                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Primary: ")
                            .foregroundColor(.primary)
                        Text(model.primaryMaterial)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray4))
                            .cornerRadius(6)
                    }

                    Spacer()

                    HStack(spacing: 0) {
                        Text("Secondary: ")
                            .foregroundColor(.primary)
                        Text(model.secondaryMaterial)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray4))
                            .cornerRadius(6)
                    }
                }
                .padding(8)
                .background(Color(.systemGray4))
                .cornerRadius(8)
            }

            // MARK: Details
            VStack(alignment: .leading, spacing: 4) {
                Text("Details:")
                    .foregroundColor(.red)
                    .bold()

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 0) {
                        HStack(alignment: .center, spacing: 4) {
                            Text("Model Type:")

                            HStack(spacing: 8) {
                                Text(model.type)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Image(systemName: Model.typeMap[model.type] ?? "camera.metering.unknown")
                                    .padding(8)
                                    .background(Color(.systemGray4))
                                    .cornerRadius(6)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()
                        
                        HStack(alignment: .center, spacing: 4) {
                            Text("Essential:")
                                .foregroundColor(.red)
                                .bold()
                            
                            Image(systemName: model.isEssential ? SFSymbols.starCircleFill : SFSymbols.circle)
                                .foregroundColor(model.isEssential ? .yellow : .gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray4))
                .cornerRadius(8)
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}
