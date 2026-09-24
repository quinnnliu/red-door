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

    private actor CacheStore {
        var entries: [String: CacheEntry] = [:]
        func get(_ key: String) -> CacheEntry? { entries[key] }
        func set(_ key: String, _ entry: CacheEntry) { entries[key] = entry }
        func remove(_ key: String) { entries.removeValue(forKey: key) }
    }

    private let cache = CacheStore()
    private let ttl: TimeInterval = 15 * 60  // 15 minutes

    // MARK: - Cache Access

    func getAll<T: ConfigurationOption>(
        using repository: GenericRepository<T>
    ) async throws -> [T] {
        let key = T.collectionPath
        if let entry = await cache.get(key),
           Date().timeIntervalSince(entry.fetchedAt) < ttl,
           let values = entry.values as? [T] {
            return values
        }
        let fresh = try await repository.getAll()
        await cache.set(key, CacheEntry(values: fresh, fetchedAt: Date()))
        return fresh
    }

    func invalidate<T: ConfigurationOption>(_ type: T.Type) {
        Task { await cache.remove(T.collectionPath) }
    }

    // MARK: - Preload

    func preload() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = try? await self.getAll(using: EssentialsGroupTypeRepository())
            }
            group.addTask {
                _ = try? await self.getAll(using: AccessoriesTypeRepository())
            }
            group.addTask {
                _ = try? await self.getAll(using: WarehouseRepository())
            }
        }
    }
}
