# ClipboardShelf Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a lightweight macOS menu bar clipboard history app that stores recent plain-text clipboard entries and lets users quickly re-copy them.

**Architecture:** ClipboardShelf should be a native SwiftUI menu bar app backed by a small `ClipboardStore` and a `PasteboardMonitor` service. Keep v1 intentionally narrow: plain text only, local persistence only, one compact popover UI, and no sync or heavy settings surface.

**Tech Stack:** Swift 6, SwiftUI, AppKit (`NSPasteboard`), Swift Package Manager, `XCTest`

---

## Product Scope

### V1 In Scope

- Menu bar app with a compact popover
- Automatic capture of plain-text clipboard entries
- Deduplicated history list
- Re-copy any saved entry with one click
- Basic search/filter in the popover
- Persistence across relaunches
- Clear history action
- Fixed history cap of 25 entries

### V1 Out of Scope

- Image, file, or rich-text clipboard capture
- Cloud sync
- Tags, folders, or pinned items
- OCR, AI, or summarization features
- Global keyboard shortcuts
- Launch-at-login

## Core Decisions

- App shape: `MenuBarExtra` only, no main Dock-style app window
- Data model: plain text items only
- Storage: JSON file in Application Support
- Clipboard detection: poll `NSPasteboard.general.changeCount` on a short timer
- Deduplication rule: if the newest captured text matches the current first item exactly, do not insert a duplicate
- History cap: keep only the 25 most recent entries
- Search behavior: case-insensitive substring match over item text

## File Structure

- `Package.swift`
  Defines the app and library targets.
- `Sources/ClipboardShelf/App/ClipboardShelfApp.swift`
  App entrypoint and `MenuBarExtra` wiring.
- `Sources/ClipboardShelf/UI/ClipboardShelfMenuView.swift`
  Top-level menu bar popover view.
- `Sources/ClipboardShelf/UI/ClipboardHistoryRow.swift`
  Single history row view.
- `Sources/ClipboardShelf/Models/ClipboardItem.swift`
  Value type for stored clipboard entries.
- `Sources/ClipboardShelf/Stores/ClipboardStore.swift`
  In-memory state plus persistence orchestration.
- `Sources/ClipboardShelf/Services/PasteboardMonitor.swift`
  Watches pasteboard changes and publishes new plain-text captures.
- `Sources/ClipboardShelf/Services/PersistenceService.swift`
  Reads and writes JSON history to disk.
- `Sources/ClipboardShelf/Support/AppPaths.swift`
  Resolves Application Support file locations.
- `Tests/ClipboardShelfTests/ClipboardStoreTests.swift`
  Deduplication, cap, clear, search, and re-copy behavior tests.
- `Tests/ClipboardShelfTests/PersistenceServiceTests.swift`
  Save/load behavior tests.
- `Tests/ClipboardShelfTests/PasteboardMonitorTests.swift`
  Pasteboard change detection tests using a fake pasteboard client.
- `script/build_and_run.sh`
  Local build/run entrypoint.
- `.codex/environments/environment.toml`
  Codex Run button wiring.

## Public Types And Interfaces

### `ClipboardItem`

- Fields:
  - `id: UUID`
  - `text: String`
  - `capturedAt: Date`

### `ClipboardStore`

- Responsibilities:
  - Own current history state
  - Insert new clipboard entries
  - Deduplicate consecutive duplicates
  - Enforce 25-item cap
  - Save/load persisted history
  - Expose filtered results for search
- API:
  - `load()`
  - `handleCapturedText(_ text: String)`
  - `copyItem(_ item: ClipboardItem)`
  - `clearHistory()`
  - `filteredItems(query: String) -> [ClipboardItem]`

### `PasteboardMonitor`

- Responsibilities:
  - Watch `NSPasteboard.general.changeCount`
  - Read current plain-text string when content changes
  - Ignore non-text clipboard payloads
- API:
  - `start()`
  - `stop()`
  - callback or publisher for newly captured text

### `PersistenceService`

- Responsibilities:
  - Encode/decode `[ClipboardItem]`
  - Store history in Application Support
- API:
  - `loadHistory() throws -> [ClipboardItem]`
  - `saveHistory(_ items: [ClipboardItem]) throws`

## Weekend Build Plan

### Task 1: Scaffold The App Shell

**Files:**
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Package.swift`
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Sources/ClipboardShelf/App/ClipboardShelfApp.swift`
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/script/build_and_run.sh`
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/.codex/environments/environment.toml`

- [ ] Create a new SwiftPM macOS app target plus test target.
- [ ] Wire a `MenuBarExtra` entry with a placeholder view and no main app window.
- [ ] Add `build_and_run.sh` using the same local `.app` bundle pattern as Lockey.
- [ ] Run the app once to confirm the menu bar shell appears.

### Task 2: Define Models And Persistence

**Files:**
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Sources/ClipboardShelf/Models/ClipboardItem.swift`
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Sources/ClipboardShelf/Services/PersistenceService.swift`
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Sources/ClipboardShelf/Support/AppPaths.swift`
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Tests/ClipboardShelfTests/PersistenceServiceTests.swift`

- [ ] Write tests for saving and loading clipboard items from disk.
- [ ] Implement `ClipboardItem` as a small codable value type.
- [ ] Implement `PersistenceService` using JSON in Application Support.
- [ ] Verify load returns an empty array when the history file does not exist.

### Task 3: Build The Store

**Files:**
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Sources/ClipboardShelf/Stores/ClipboardStore.swift`
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Tests/ClipboardShelfTests/ClipboardStoreTests.swift`

- [ ] Write tests for:
  - inserting a new item
  - rejecting consecutive duplicates
  - trimming history beyond 25 items
  - clearing history
  - filtering items by search query
- [ ] Implement `ClipboardStore` as the single source of truth for history state.
- [ ] Add persistence calls so state reloads on app launch and saves after mutations.

### Task 4: Add Pasteboard Monitoring

**Files:**
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Sources/ClipboardShelf/Services/PasteboardMonitor.swift`
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Tests/ClipboardShelfTests/PasteboardMonitorTests.swift`

- [ ] Define a small pasteboard client abstraction so tests do not depend on the real system pasteboard.
- [ ] Write tests for:
  - detecting changeCount changes
  - ignoring unchanged pasteboard state
  - ignoring non-text content
  - forwarding newly captured text once
- [ ] Implement a timer-based monitor using `NSPasteboard.general.changeCount`.
- [ ] Wire the monitor into `ClipboardStore.handleCapturedText(_:)`.

### Task 5: Build The Popover UI

**Files:**
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Sources/ClipboardShelf/UI/ClipboardShelfMenuView.swift`
- Create: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Sources/ClipboardShelf/UI/ClipboardHistoryRow.swift`
- Modify: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Sources/ClipboardShelf/App/ClipboardShelfApp.swift`

- [ ] Create a compact menu bar popover with:
  - title
  - search field
  - scrollable history list
  - `Clear History` action
- [ ] Each row should show:
  - first line of clipboard text
  - capture timestamp in smaller secondary text
  - copy action on click
- [ ] Keep row layout shallow and native-looking; no custom heavy cards.
- [ ] When there are no items, show a simple empty state.

### Task 6: Finish Copy-Back Behavior

**Files:**
- Modify: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Sources/ClipboardShelf/Stores/ClipboardStore.swift`
- Modify: `/Users/rumipro/Documents/MacApps/ClipboardShelf/Tests/ClipboardShelfTests/ClipboardStoreTests.swift`

- [ ] Add a pasteboard writer abstraction for tests.
- [ ] Write a test proving `copyItem(_:)` writes the selected text back to the system pasteboard.
- [ ] Ensure re-copying an older item does not create duplicate state glitches on the next monitor tick.

### Task 7: Polish And Verify

**Files:**
- Modify only as needed in the files above.

- [ ] Add concise empty-state and error-state messaging.
- [ ] Run the full test suite.
- [ ] Run the app manually and validate:
  - new copied text appears
  - clicking an item copies it again
  - duplicates are suppressed
  - history persists after relaunch
  - clear history works

## Acceptance Criteria

- The app lives in the menu bar and opens a compact SwiftUI popover.
- Copying plain text in another app adds an item to ClipboardShelf within about 1 second.
- The same consecutive clipboard value is not inserted twice.
- Only the 25 most recent entries are retained.
- Search filters the visible list correctly.
- Clicking a history row copies that item back to the pasteboard.
- Clipboard history survives app relaunch.
- The app remains stable when the clipboard contains non-text content.

## Test Plan

- Unit tests for `ClipboardStore`
- Unit tests for `PersistenceService`
- Unit tests for `PasteboardMonitor`
- Manual checks for real clipboard capture and re-copy behavior

## Risks And Mitigations

- Pasteboard polling can feel wasteful if too aggressive.
  Use a modest interval such as 0.5 to 1.0 seconds for v1.
- Clipboard monitoring can accidentally capture app-internal re-copy actions repeatedly.
  Suppress only consecutive duplicates in v1; that is enough to avoid obvious loops.
- Large clipboard text can make the menu hard to scan.
  Truncate visible text in rows and keep the full value in storage.

## Assumptions

- This is a personal/direct-use macOS app, not a Mac App Store product.
- v1 targets macOS 14+.
- v1 is plain text only.
- v1 uses local JSON persistence with no encryption.
- v1 favors a menu bar utility over a full main window.

## Suggested Repo Description

ClipboardShelf is a lightweight macOS menu bar app that keeps a searchable history of recent plain-text clipboard entries so you can quickly find and re-copy what you copied earlier.
