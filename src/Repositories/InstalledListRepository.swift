//
//  InstalledListRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/8/26.
//

import Foundation

final class InstalledListRepository: GenericRepository<InstalledListV2> {
    func getAllInstalled() async throws -> [InstalledListV2] {
        let snapshot = try await collectionRef
            .whereField(InstalledListV2.CodingKeys.uninstalled.stringValue, isEqualTo: false)
            .order(by: InstalledListV2.CodingKeys.installDate.stringValue, descending: true)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: InstalledListV2.self) }
    }
}
