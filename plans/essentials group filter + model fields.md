# Plan: Essentials Group Filter + Model Fields (groupNumber, nickname)

## Context

Two related changes:
1. **Model-level**: Add `groupNumber: Int` and `nickname: String?` to `EssentialsGroup` — mirroring the `itemNumber`/`nickname` fields added to `ItemV2` to distinguish items with the same name. `groupNumber` is auto-assigned at creation time by querying the max existing value. `nickname` is optional user-provided text.
2. **Filter UI**: Add an essentials group filter row to `ItemV2DocumentFilterSheet` so users can filter the items list to only items belonging to a specific group.

---

## Part 1: EssentialsGroup Model + Repository + ViewModel

### `src/Models-v2/EssentialsGroup.swift`

Add two new fields after `accessoriesId`:
```swift
let groupNumber: Int
let nickname: String?
```

Add CodingKeys:
```swift
case groupNumber = "group_number"
case nickname  // matches "nickname" directly, no alias needed
```

Update `init` signature:
```swift
init(
    id: String = UUID().uuidString,
    displayName: String,
    status: LocationStatus = .inStorage,
    locationId: String = Warehouse.warehouse1.id,
    essentialsTypeId: String,
    itemIds: [String] = [],
    accessoriesId: String? = nil,
    groupNumber: Int = 0,      // new
    nickname: String? = nil    // new
) {
    // ... existing assignments ...
    self.groupNumber = groupNumber
    self.nickname = nickname
}
```

---

### `src/Repositories/EssentialsRepository.swift`

Expand `EssentialsRepository` from a thin wrapper to include `maxGroupNumber()`, mirroring `ItemRepository.maxItemNumber(forModelId:)` but scoped globally across all groups (not per-model):

```swift
final class EssentialsRepository: GenericRepository<EssentialsGroup> {
    func maxGroupNumber() async throws -> Int {
        let snapshot = try await collectionRef
            .order(by: "group_number", descending: true)
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.first
            .flatMap { $0.data()["group_number"] as? Int } ?? 0
    }
}
```

---

### `src/Essentials-v2/ViewModels/CreateEssentialsGroupViewModel.swift`

Add a `nickname` state property (so the creation UI can bind to it):
```swift
var nickname: String = ""
```

Update `createEssentialsGroup()` to fetch the next group number before constructing the group:
```swift
func createEssentialsGroup() async -> Bool {
    guard let selectedGroupType else { return false }
    isLoading = true
    defer { isLoading = false }
    do {
        let maxNumber = try await essentialsRepo.maxGroupNumber()
        let group = EssentialsGroup(
            displayName: selectedGroupType.displayName,
            essentialsTypeId: selectedGroupType.id,
            accessoriesId: selectedAccessory?.id,
            groupNumber: maxNumber + 1,
            nickname: nickname.isEmpty ? nil : nickname
        )
        try essentialsRepo.set(document: group)
        return true
    } catch {
        return false
    }
}
```

---

## Part 2: Essentials Group Filter in ItemV2DocumentFilterSheet

### `src/DocumentsList-v2/Views/Filter/ItemV2DocumentFilterSheet.swift`

**Add stored property + state:**
```swift
let availableGroups: [EssentialsGroup]
@State private var selectedGroup: EssentialsGroup?
```

**Update `init` signature and body:**
```swift
init(action: @escaping (Any?) -> Void, initialFilters: [String: AnyHashable] = [:], availableGroups: [EssentialsGroup] = []) {
    self.action = action
    self.availableGroups = availableGroups
    // ... existing filter parsing ...
    let groupId = initialFilters[ItemV2.CodingKeys.essentialGroupId.stringValue] as? String
    _selectedGroup = State(initialValue: availableGroups.first { $0.id == groupId })
}
```

**Add `EssentialsGroupRow` subview** (private extension, same pattern as `AttentionRow`):
```swift
var EssentialsGroupRow: some View {
    HStack {
        Text("Essentials Group")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        Spacer()
        Picker("", selection: $selectedGroup) {
            Text("Any").tag(Optional<EssentialsGroup>.none)
            ForEach(availableGroups) { group in
                Text(group.displayName).tag(Optional(group))
            }
        }
        .pickerStyle(.menu)
        .tint(selectedGroup != nil ? .red : .secondary)
    }
    .padding(.vertical, 12)
    .overlay(alignment: .bottom) { Divider() }
}
```

Add to the ScrollView VStack only if `!availableGroups.isEmpty`:
```swift
if !availableGroups.isEmpty {
    EssentialsGroupRow
}
```

**Update actions:**
- `hasActiveFilters`: add `|| selectedGroup != nil`
- `buildFilterDictionary()`: add `if let group = selectedGroup { filters[ItemV2.CodingKeys.essentialGroupId.stringValue] = group.id }`
- `resetFilters()`: add `selectedGroup = nil`

---

### `src/DocumentsList-v2/Views/ItemDocumentListViewV2.swift`

**Update `InventorySegment.filterSheet` method** to accept and forward groups:
```swift
func filterSheet(action: @escaping (Any?) -> Void, initialFilters: [String: AnyHashable] = [:], availableGroups: [EssentialsGroup] = []) -> some View {
    switch self {
    case .items:
        ItemV2DocumentFilterSheet(action: action, initialFilters: initialFilters, availableGroups: availableGroups)
    case .essentials:
        Text("FilterSheetView for \(self.title)")
    case .accessories:
        Text("FilterSheetView for \(self.title)")
    }
}
```

**Update `.sheet` call site:**
```swift
.sheet(item: $filterDocumentSheetType) { type in
    type.filterSheet(
        action: handleAction(_:),
        initialFilters: activeFilters(for: type),
        availableGroups: essentialsVM.documents
    )
    .presentationDetents([.large])
}
```

Note: `essentialsVM.documents` uses whatever is currently loaded (pageSize 50). The group row is hidden when the list is empty.

---

## Files Modified

| File | Change |
|------|--------|
| `src/Models-v2/EssentialsGroup.swift` | Add `groupNumber: Int`, `nickname: String?`, CodingKeys, initializer params |
| `src/Repositories/EssentialsRepository.swift` | Add `maxGroupNumber()` |
| `src/Essentials-v2/ViewModels/CreateEssentialsGroupViewModel.swift` | Add `nickname` var, fetch `maxGroupNumber()` and pass both at creation |
| `src/DocumentsList-v2/Views/Filter/ItemV2DocumentFilterSheet.swift` | Add group filter row, state, init param, and action updates |
| `src/DocumentsList-v2/Views/ItemDocumentListViewV2.swift` | Pass `availableGroups` through `filterSheet(...)` to the sheet |

---

## Verification

Build the project and confirm zero build errors (`Cmd+B` / `xcodebuild`).
