# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Red Door Design + Staging inventory management iOS app. Stack: SwiftUI, Firebase (Firestore + Storage), iOS 17+, `@Observable` macro (no `ObservableObject`/`@Published`).

Requires `GoogleService-Info.plist` (not committed) for Firebase to work.

## Active V2 Refactor

The codebase is mid-refactor. **V1** code lives in `src/Models/`, `src/ViewModels/`, `src/Views/`. **V2** code lives in feature folders (`src/[Feature]-v2/`, `src/Models-v2/`, `src/Repositories/`, `src/DocumentsList-v2/`). Any file or type with `V2` or `-v2` in its name is the new implementation. Prefer V2 patterns for all new work. See `src/Architecture Discussions/Architecture-v2.md` for the full design rationale.

## V2 Architecture

### Data Layer

**`RDDocument`** (`src/Protocols-v2/RDDocument.swift`) — every Firestore model conforms to this protocol:
```swift
protocol RDDocument: Codable, Hashable, Identifiable {
    var id: String { get }
    var baseName: String { get }
    var nickname: String? { get }             // defaults to nil via extension

    static var collectionName: String { get }
    static var collectionPath: String { get }  // defaults to collectionName via extension
    static var orderByField: String { get }    // default sort field
    static var searchField: String { get }

    static func normalizeSearchText(_ text: String) -> String
}
```
The protocol extension provides `displayName { nickname ?? baseName }` and default implementations for `collectionPath` and `normalizeSearchText`. `ConfigurationOption` (`src/Protocols-v2/ConfigurationOption.swift`) extends `RDDocument` and overrides `collectionPath` to nest under `app_configuration/{configurationType}/{collectionName}` (used by `WarehouseV2`, `EssentialsGroupType`, `AccessoriesType`).

**`GenericRepository<T: RDDocument>`** (`src/Repositories/GenericRepository.swift`) — base class with three operation flavors for every CRUD method:
- **Standalone async** — direct Firestore call
- **Batch participatory** — `inBatch batch: WriteBatch` overload for atomic multi-write
- **Transaction participatory** — `in transaction: Transaction` overload for read-then-write flows

Concrete repositories subclass and add only collection-specific logic (e.g., `PullListRepository`, `ItemRepository`). Repositories are plain `class`, not `actor` — they hold no mutable state.

**`FirebaseImageActor`** (`src/Services/FirebaseImageManager.swift`) — standalone `actor` (not a `GenericRepository` subclass — actors cannot inherit from classes). Caches `UIImage` via `NSCache` keyed by storage path to avoid redundant Storage downloads.

**Error handling**: there is no `AppError` type. Firebase/decoding errors propagate as raw `Error` (Firestore `NSError`, `DecodingError`, or `RepositoryError.decodeFailure` for a missing/undecodable snapshot from a listener). ViewModels catch at the call site and set `showAlert: Bool` + `alertMessage: String` (sometimes `alertText`) from `error.localizedDescription`. V2 ViewModels do `import Firebase` directly — the "never import Firebase in ViewModels" boundary is aspirational, not current practice.

### ViewModel Layer

**`DocumentListViewModelV2<T: RDDocument>`** (`src/DocumentsList-v2/ViewModels/DocumentListViewModelV2.swift`) — generic, reusable paginated list ViewModel. Handles pagination (cursor-based), search, and key-value filters. Use this for any list screen instead of writing a new one.

ViewModels are scoped to an entire screen, screen-specific, and are small and focused (e.g., `CreatePullListViewModelV2`) — they own only the logic their screen needs and inject repositories at init.

### Action Handling

Generic components fire screen-specific actions via type-casting dispatch. Parent screen defines an action handler; component passes action enums.

Parent screen pattern (illustrative skeleton — see real examples below):
```swift
private extension SomeScreenV2 {
    func handleAction(_ action: Any?) {
        switch action {
        case let action as SearchBarAction:
            // dispatch to viewModel based on action case
        case let action as SomeComponentAction:
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

`action` closures are typically `(Any?) -> Void` (not `(Any) -> Void`) so a `default: break`/`guard actionArgument != nil else { return }` can no-op cleanly. See `src/PullList-v2/Screens/InstallPullListSheet/InstallPullListSheet.swift` (dispatches `RoomListItemViewAction`, `InstallPullListRoomAction`, `ConfirmInstallSheetAction`) and `src/Components-v2/SearchBarV2.swift` for full implementations.

### Navigation

All navigation types live in `src/Navigation-v2/`, not `src/Navigation/`:

**`NavigationCoordinator`** (`src/Navigation-v2/NavigationCoordinatorV2.swift`) — `@Observable` class injected via `@Environment`. Owns a `NavigationPath` per tab (`enum Tab`), plus `setSelectedTab(to:)`, `appendToSelectedPath(_:)`, `removeFromSelectedPath(_:)`, `resetSelectedPath()`.

**`NavigationDestinationsModifierV2`** (`src/Navigation-v2/NavigationDestinationModifierV2.swift`) — registers all `.navigationDestination` handlers in one place. Applied at the root of each tab stack via `.rootNavigationDestinationsV2(path:)`. Add new destination types here. Destinations that need view-model construction route through a `*ViewFactory` struct (e.g. `InstalledListViewFactory`, `PullListViewFactory`) rather than being built inline.

**`NavigationDestination`** (`src/Navigation-v2/NavigationDestinations.swift`) - enum that defines destinations for any screen in the app. Each destination has associated values that are needed for initializing the screen and/or its ViewModel. Not every screen needs a case here — screens presented via `.sheet`/`.fullScreenCover` (e.g. `InstallPullListSheet`) are constructed directly, not routed through this enum.

**`ContentView`** (`src/App/ContentView.swift`) — tab root. V1 tabs are commented out; active tabs use V2 views.

### Firestore Conventions

- Collection names: snake_case, lowercase (e.g., `pull_list_v2`, `installed_list_v2`, `items_v2`, `rooms`) — not `pull_list_V2`
- Document IDs: UUID strings, except `RoomV2` uses a lowercased hyphenated room name
- Subcollections: rooms live under `pull_list_v2/{listId}/rooms` or `installed_list_v2/{listId}/rooms`, per `RoomRepository`'s `init(list:)` / `init(parentCollectionName:listId:)`
- CodingKeys: snake_case Firestore fields mapped to camelCase Swift properties
- `ConfigurationOption` documents (warehouses, essentials types, accessories types) nest under `app_configuration/{configurationType}/{collectionName}` and are fetched/cached via `ConfigurationService.shared.getAll(using: someRepo)` (15 min TTL)

### Real-Time Listeners

Use listeners **only** for single-document detail views (attach in `startListening()`, detach in `stopListening()`, called from `.task`/`.onDisappear`). List views use one-time fetches via `DocumentListViewModelV2`.

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

## Claude Guidelines

- When given a task or implementation suggestion, do some diligence to check whether this is the correct architectural choice for implementation and feel free surface concerns to the user.
- When writing plans don't verify. The user will build and test the app.
