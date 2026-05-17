# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Red Door Design + Staging inventory management iOS app. Stack: SwiftUI, Firebase (Firestore + Storage), iOS 17+, `@Observable` macro (no `ObservableObject`/`@Published`).

## Build & Run

```bash
# Build (no workspace — use .xcodeproj directly)
xcodebuild -project RedDoor.xcodeproj -scheme RedDoor -configuration Debug build

# Build for simulator
xcodebuild -project RedDoor.xcodeproj -scheme RedDoor -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run on simulator
xcrun simctl boot "iPhone 15"
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/RedDoor.app
xcrun simctl launch booted com.quinnliu.reddoor
```

No linting config (Xcode warnings only). No tests exist yet.

Requires `GoogleService-Info.plist` (not committed) for Firebase to work.

## Active V2 Refactor

The codebase is mid-refactor. **V1** code lives in `src/Models/`, `src/ViewModels/`, `src/Views/`. **V2** code lives in feature folders (`src/[Feature]-v2/`, `src/Models-v2/`, `src/Repositories/`, `src/DocumentsList-v2/`). Any file or type with `V2` or `-v2` in its name is the new implementation. Prefer V2 patterns for all new work. See `src/Architecture Discussions/Architecture-v2.md` for the full design rationale.

## V2 Architecture

### Data Layer

**`AnyRDDocument`** (`src/Models-v2/AnyRDDocument.swift`) — every Firestore model conforms to this protocol:
```swift
protocol AnyRDDocument: Codable, Hashable, Identifiable {
    var id: String { get }
    static var collectionName: String { get }  // Firestore collection path
    static var orderByField: String { get }    // default sort field
}
```

**`GenericRepository<T: AnyRDDocument>`** (`src/Repositories/GenericRepository.swift`) — base class with three operation flavors for every CRUD method:
- **Standalone async** — direct Firestore call
- **Batch participatory** — `inBatch batch: WriteBatch` overload for atomic multi-write
- **Transaction participatory** — `in transaction: Transaction` overload for read-then-write flows

Concrete repositories subclass and add only collection-specific logic (e.g., `PullListRepository`, `ItemRepository`). Repositories are plain `class`, not `actor` — they hold no mutable state.

**`RoomRepository`** has a failable `init?(list:)` because rooms are a subcollection nested under a parent document (`pull_list_V2/{id}/rooms`), not a top-level collection.

**`FirebaseImageActor`** (`src/Services/FirebaseImageManager.swift`) — standalone `actor` (not a `GenericRepository` subclass — actors cannot inherit from classes). Caches `UIImage` via `NSCache` keyed by storage path to avoid redundant Storage downloads.

**Error handling**: all Firebase/decoding errors must be mapped to `AppError` at the repository boundary so ViewModels never import Firebase.

### ViewModel Layer

**`DocumentListViewModelV2<T: AnyRDDocument>`** (`src/DocumentsList-v2/ViewModels/DocumentListViewModelV2.swift`) — generic, reusable paginated list ViewModel. Handles pagination (cursor-based), search, and key-value filters. Use this for any list screen instead of writing a new one.

Screen-specific ViewModels (e.g., `CreatePullListViewModelV2`) are small and focused — they own only the logic their screen needs and inject repositories at init.

### Navigation

**`NavigationCoordinator`** (`src/Navigation/NavigationCoordinator.swift`) — `@Observable` class injected via `@Environment`. Owns each tab's `NavigationPath`.

**`NavigationDestinationsModifierV2`** (`src/Navigation/NavigationDestinationModifier-v2.swift`) — registers all `.navigationDestination` handlers in one place. Applied at the root of each tab stack via `.rootNavigationDestinationsV2(path:)`. Add new destination types here.

**`ContentView`** (`src/App/ContentView.swift`) — tab root. V1 tabs are commented out; active tabs use V2 views.

### Firestore Conventions

- Collection names: snake_case (e.g., `pull_list_V2`, `rooms`, `items`)
- Document IDs: UUID strings, except `RoomV2` uses a lowercased hyphenated room name
- Subcollections: rooms live under `pull_list_V2/{listId}/rooms`
- CodingKeys: snake_case Firestore fields mapped to camelCase Swift properties

### Real-Time Listeners

Use listeners **only** for single-document detail views (attach in `activate()`, detach in `deactivate()`, called from `onAppear`/`onDisappear`). List views use one-time fetches via `DocumentListViewModelV2`.

## Code Style

File header:
```swift
//
//  Filename.swift
//  RedDoor
//
//  Created by Quinn Liu on MM/DD/YY.
//
```

- `@Observable` + `final class` for all ViewModels
- `private` repository properties in ViewModels
- Use `// MARK: -` to section ViewModels and views
- Capture repositories directly (not `self`) inside transaction closures to avoid retain cycles
