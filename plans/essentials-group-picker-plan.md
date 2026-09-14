# Plan: Essentials Group Picker in Create/Edit Item Views

## Context

`CreateItemsViewV2` and `EditItemSheetV2` both render `EditItemDetailSection`, which currently shows a read-only `Text(essentialGroupId ?? "")`. This needs to become an interactive `SelectDocumentSheet<EssentialsGroup>` picker so users can assign an item to an essentials group at create/edit time.

Two Firestore documents must stay in sync on any change:
- The **item** stores `essentialGroupId: String?`
- The **group** stores `itemIds: [String]`

**Key architectural note:** `ItemDetailViewModel.item` is continuously updated by a realtime listener. We cannot store `originalEssentialGroupId` in the ViewModel — it would go stale the moment the listener fires after a save. Instead, `EditItemSheetV2` captures the old group ID at the moment of save from `editingItem` (snapshotted when the sheet opened) and passes it into `updateItem(oldGroupId:)`.

---

## Files to Modify

1. `src/Repositories/EssentialsRepository.swift`
2. `src/Item-v2/ViewModels/ItemDetailViewModel.swift`
3. `src/Item-v2/ViewModels/CreateItemsViewModel.swift`
4. `src/Item-v2/Views/Components/EditItemDetailSection.swift`
5. `src/Item-v2/Views/CreateItemsViewV2.swift`
6. `src/Item-v2/Views/EditItemSheetV2.swift`

---

## Implementation

### 1. EssentialsRepository

Add `arrayUnion`/`arrayRemove` helpers using `collectionRef` directly (keeps `FieldValue` out of ViewModels):

```swift
func addItem(_ itemId: String, toGroup groupId: String) async throws {
    try await collectionRef.document(groupId).updateData([
        EssentialsGroup.CodingKeys.itemIds.stringValue: FieldValue.arrayUnion([itemId])
    ])
}

func removeItem(_ itemId: String, fromGroup groupId: String) async throws {
    try await collectionRef.document(groupId).updateData([
        EssentialsGroup.CodingKeys.itemIds.stringValue: FieldValue.arrayRemove([itemId])
    ])
}
```

### 2. ItemDetailViewModel

Add group loading:

```swift
private let essentialsRepo: EssentialsRepository = .init()
var availableGroups: [EssentialsGroup] = []

func loadGroups() async {
    do { availableGroups = try await essentialsRepo.getAll() }
    catch { print("error loading groups: \(error)") }
}
```

Change `updateItem()` → `updateItem(oldGroupId: String?)`. After the existing item save logic, add:

```swift
let newGroupId = item.essentialGroupId
if newGroupId != oldGroupId {
    if let old = oldGroupId {
        try await essentialsRepo.removeItem(item.id, fromGroup: old)
    }
    if let new = newGroupId {
        try await essentialsRepo.addItem(item.id, toGroup: new)
    }
}
```

### 3. CreateItemsViewModel

```swift
private let essentialsRepo: EssentialsRepository = .init()
var availableGroups: [EssentialsGroup] = []
var selectedGroup: EssentialsGroup? = nil

func loadGroups() async {
    do { availableGroups = try await essentialsRepo.getAll() }
    catch { print("error loading groups: \(error)") }
}
```

In `createItems()`, before building items:
```swift
itemState.essentialGroupId = selectedGroup?.id
```

After `try await batch.commit()`:
```swift
if let group = selectedGroup {
    for item in updatedItems {
        try await essentialsRepo.addItem(item.id, toGroup: group.id)
    }
}
```

### 4. EditItemDetailSection

Replace:
```swift
@Binding var essentialGroupId: String?
```
With:
```swift
@Binding var selectedGroup: EssentialsGroup?
let groups: [EssentialsGroup]
@State private var showGroupPicker: Bool = false
```

In `DetailsSection`, replace the read-only "Essential" `HStack` with:
```swift
Button { showGroupPicker = true } label: {
    HStack {
        Text("Essential:")
            .foregroundColor(.red)
            .bold()
        Spacer()
        Text(selectedGroup?.displayName ?? "None")
            .foregroundColor(.blue)
    }
}
.sheet(isPresented: $showGroupPicker) {
    SelectDocumentSheet(title: "Select Essentials Group", documents: groups) { action in
        guard let action = action as? SelectDocumentSheetAction<EssentialsGroup>,
              case .selected(let group) = action else { return }
        selectedGroup = group
    }
}
```

### 5. CreateItemsViewV2

Add `.task { await viewModel.loadGroups() }` on the root `ZStack`.

Update `EditItemDetailSection` call — replace `essentialGroupId: $viewModel.itemState.essentialGroupId` with:
```swift
selectedGroup: $viewModel.selectedGroup,
groups: viewModel.availableGroups,
```

### 6. EditItemSheetV2

Add local state:
```swift
@State private var selectedGroup: EssentialsGroup? = nil
```

Add `.task` on the root `ZStack`:
```swift
.task {
    await viewModel.loadGroups()
    if let groupId = editingItem.essentialGroupId {
        selectedGroup = viewModel.availableGroups.first { $0.id == groupId }
    }
}
```

Update `EditItemDetailSection` call — replace `essentialGroupId: $editingItem.essentialGroupId` with:
```swift
selectedGroup: $selectedGroup,
groups: viewModel.availableGroups,
```

Update `saveItem()`:
```swift
private func saveItem() {
    Task {
        let oldGroupId = editingItem.essentialGroupId
        editingItem.essentialGroupId = selectedGroup?.id
        viewModel.item = editingItem
        await viewModel.updateItem(oldGroupId: oldGroupId)
        dismiss()
    }
}
```
