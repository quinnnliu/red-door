//
//  ConfigurationOption.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/30/26.
//

protocol ConfigurationOption: RDDocument {
    static var configurationType: String { get }
}

extension ConfigurationOption {
    static var collectionPath: String { "app_configuration/\(configurationType)/\(collectionName)" }
}
