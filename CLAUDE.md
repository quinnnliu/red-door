# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Red Door Design + Staging inventory management iOS app. Stack: SwiftUI, Firebase (Firestore + Storage), iOS 17+, `@Observable` macro (no `ObservableObject`/`@Published`).

Requires `GoogleService-Info.plist` (not committed) for Firebase to work.

## Active V2 Refactor

The codebase is mid-refactor. **V1** code lives in `src/Models/`, `src/ViewModels/`, `src/Views/`. **V2** code lives in feature folders (`src/[Feature]-v2/`, `src/Models-v2/`, `src/Repositories/`, `src/DocumentsList-v2/`). Any file or type with `V2` or `-v2` in its name is the new implementation. Prefer V2 patterns for all new work. See `src/Architecture Discussions/Architecture-v2.md` for the full design rationale.

## V2 Architecture

### Data Layer

**`AnyRDDocument`** (`src/Models-v2/AnyRDDocument.swift`) — every Firestore model conforms to this protocol:
```swift
protocol AnyRDDocument: Codable, Hashable, Identifiable {
    var id: String { get }
    var displayName: String { get }
    static var collectionName: String { get }  // Firestore collection path
    static var orderByField: String { get }    // default sort field
    static var searchByField: String { get }
}
```

**`GenericRepository<T: AnyRDDocument>`** (`src/Repositories/GenericRepository.swift`) — base class with three operation flavors for every CRUD method:
- **Standalone async** — direct Firestore call
- **Batch participatory** — `inBatch batch: WriteBatch` overload for atomic multi-write
- **Transaction participatory** — `in transaction: Transaction` overload for read-then-write flows

Concrete repositories subclass and add only collection-specific logic (e.g., `PullListRepository`, `ItemRepository`). Repositories are plain `class`, not `actor` — they hold no mutable state.

**`FirebaseImageActor`** (`src/Services/FirebaseImageManager.swift`) — standalone `actor` (not a `GenericRepository` subclass — actors cannot inherit from classes). Caches `UIImage` via `NSCache` keyed by storage path to avoid redundant Storage downloads.

**Error handling**: all Firebase/decoding errors must be mapped to `AppError` at the repository boundary so ViewModels never import Firebase.

### ViewModel Layer

**`DocumentListViewModelV2<T: AnyRDDocument>`** (`src/DocumentsList-v2/ViewModels/DocumentListViewModelV2.swift`) — generic, reusable paginated list ViewModel. Handles pagination (cursor-based), search, and key-value filters. Use this for any list screen instead of writing a new one.

ViewModels are scoped to an entire screen, screen-specific, and are small and focused (e.g., `CreatePullListViewModelV2`) — they own only the logic their screen needs and inject repositories at init.

### Action Handling

Generic components fire screen-specific actions via type-casting dispatch. Parent screen defines an action handler; component passes action enums.

Parent screen pattern:
```swift
private extension RoomAddItemsSheetV2 {
    func handleAction(_ action: Any?) {
        switch action {
        case let action as SearchBarAction:
            // dispatch to viewModel based on action case
        case let action as ItemInventoryFilterViewAction:
            // dispatch to viewModel based on action case
        default: break
        }
    }
}
```

Component pattern:
```swift
struct SearchBarV2: View {
    private let action: (Any) -> Void
    // ... view code emits: action(SearchBarAction.search(text:)) or action(SearchBarAction.cancel)
}

enum SearchBarAction { case search(text: String); case cancel }
```

See `RoomAddItemsSheetV2.swift` and `SearchBarV2.swift` for full implementations.

### Navigation

**`NavigationCoordinator`** (`src/Navigation/NavigationCoordinator.swift`) — `@Observable` class injected via `@Environment`. Owns each tab's `NavigationPath`.

**`NavigationDestinationsModifierV2`** (`src/Navigation/NavigationDestinationModifier-v2.swift`) — registers all `.navigationDestination` handlers in one place. Applied at the root of each tab stack via `.rootNavigationDestinationsV2(path:)`. Add new destination types here.

**`NavigationDestinations`** (`src/Navigation/NavigationDestinations.swift`) - enum that defines destinations for any screen in the app. Each destination has associated values that are needed for initializing the screen and/or its ViewModel.

**`ContentView`** (`src/App/ContentView.swift`) — tab root. V1 tabs are commented out; active tabs use V2 views.

### Firestore Conventions

- Collection names: snake_case (e.g., `pull_list_V2`, `rooms`, `items`)
- Document IDs: UUID strings, except `RoomV2` uses a lowercased hyphenated room name
- Subcollections: rooms live under `pull_list_V2/{listId}/rooms`
- CodingKeys: snake_case Firestore fields mapped to camelCase Swift properties

### Real-Time Listeners

Use listeners **only** for single-document detail views (attach in `activate()`, detach in `deactivate()`, called from `onAppear`/`onDisappear`). List views use one-time fetches via `DocumentListViewModelV2`.

**`GenericRepository<T>`** provides typed listeners:
```swift
func addDocumentListener(id: String, onChange: @escaping (Result<T, Error>) -> Void) -> ListenerRegistration
func addCollectionListener(onChange: @escaping (Result<[T], Error>) -> Void) -> ListenerRegistration
```

See `src/Repositories/GenericRepository.swift` for full signatures.

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
