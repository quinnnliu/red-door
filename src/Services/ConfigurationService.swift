//
//  ConfigurationService.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/30/26.
//

import Foundation
import Observation

@Observable
final class ConfigurationService {
    static let shared = ConfigurationService()
    private init() { }

    private struct CacheEntry {
        let values: Any
        let fetchedAt: Date
    }

    private var cache: [String: CacheEntry] = [:]
    private let ttl: TimeInterval = 15 * 60  // 15 minutes

    // MARK: - Cache Access

    func getAll<T: ConfigurationOption>(
        using repository: GenericRepository<T>
    ) async throws -> [T] {
        let key = T.collectionPath
        if let entry = cache[key],
           Date().timeIntervalSince(entry.fetchedAt) < ttl,
           let values = entry.values as? [T] {
            return values
        }
        let fresh = try await repository.getAll()
        cache[key] = CacheEntry(values: fresh, fetchedAt: Date())
        return fresh
    }

    func invalidate<T: ConfigurationOption>(_ type: T.Type) {
        cache.removeValue(forKey: T.collectionPath)
    }

    // MARK: - Preload

    func preload() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = try? await self.getAll(using: EssentialsGroupTypeRepository())
            }
            // Add future ConfigurationOption types here
        }
    }
}
