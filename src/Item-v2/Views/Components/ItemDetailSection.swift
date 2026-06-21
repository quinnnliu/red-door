//
//  ItemDetailSection.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import SwiftUI

struct ItemDetailSection: View {
    let item: ItemV2
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: Description
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel("Description:")
                Text(item.description.isEmpty ? "No description" : item.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(item.description.isEmpty ? .secondary : .primary)
                    .padding(8)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
            }
            
            // MARK: Type, Color, Material
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel("Details:")
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Type:")
                            .frame(width: 90, alignment: .leading)
                        Text(item.type.title)
                            .padding(6)
                            .background(Color(.systemGray4))
                            .cornerRadius(6)
                    }
                    
                    HStack {
                        Text("Color:")
                            .frame(width: 90, alignment: .leading)
                        HStack(spacing: 6) {
                            Image(systemName: SFSymbols.circleFill)
                                .foregroundStyle(item.color.color)
                            Text(item.color.title)
                        }
                        .padding(6)
                        .background(Color(.systemGray4))
                        .cornerRadius(6)
                    }
                    
                    HStack {
                        Text("Material:")
                            .frame(width: 90, alignment: .leading)
                        Text(item.material.title)
                            .padding(6)
                            .background(Color(.systemGray4))
                            .cornerRadius(6)
                    }
                    
                    HStack {
                        Text("Essential:")
                            .frame(width: 90, alignment: .leading)
                        if let essentialGroupId = item.essentialGroupId {
                            Text(essentialGroupId)
                        } else {
                            Image(systemName: SFSymbols.circle)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("Status:")
                        Text(item.status.displayTitle)
                            .padding(4)
                            .background(item.status == .inStorage ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            .cornerRadius(4)
                            .foregroundColor(item.status == .inStorage ? .green : .red)
                    }
                }
                .padding(8)
                .background(Color(.systemGray4))
                .cornerRadius(8)
            }
            
            // MARK: Purchase Info (only shown if any field is set)
            if item.value != nil || item.brand != nil || item.purchaseLocation != nil || item.datePurchased != nil {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel("Purchase Info:")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let value = item.value {
                            HStack {
                                Text("Value ($):")
                                    .frame(width: 120, alignment: .leading)
                                Text(String(format: "%.2f", value))
                                    .padding(6)
                                    .background(Color(.systemGray4))
                                    .cornerRadius(6)
                            }
                        }
                        if let brand = item.brand {
                            HStack {
                                Text("Brand:")
                                    .frame(width: 120, alignment: .leading)
                                Text(brand)
                                    .padding(6)
                                    .background(Color(.systemGray4))
                                    .cornerRadius(6)
                            }
                        }
                        if let location = item.purchaseLocation {
                            HStack {
                                Text("Purchased At:")
                                    .frame(width: 120, alignment: .leading)
                                Text(location)
                                    .padding(6)
                                    .background(Color(.systemGray4))
                                    .cornerRadius(6)
                            }
                        }
                        if let date = item.datePurchased {
                            HStack {
                                Text("Date:")
                                    .frame(width: 120, alignment: .leading)
                                Text(date)
                                    .padding(6)
                                    .background(Color(.systemGray4))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
                }
            }
            
            // MARK: Attention
            if item.attention {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel("Attention:")
                    
                    Text(item.attentionDescription ?? "Needs attention")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
    
    private func SectionLabel(_ title: String) -> some View {
        Text(title)
            .foregroundColor(.red)
            .bold()
    }
}
