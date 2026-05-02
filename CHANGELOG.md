# Changelog

## 0.2.1 - 2026-05-02

### Fixed

- Restored the Settings button so it reliably opens the dedicated `ClipSpot Settings` window from the menu bar app

### Changed

- Repackaged the public DMG installer with the latest settings-window fix

## 0.2.0 - 2026-04-30

### Added

- Per-item delete controls in clipboard history
- Dedicated settings window for ClipSpot preferences
- Launch at login setting
- Clipboard monitoring controls
- Configurable history limit
- Configurable duplicate capture handling
- Media preview toggle
- Delete and clear confirmation settings
- Configurable hotkey presets
- Excluded apps list for frontmost-app capture suppression
- Maintenance actions for clearing history, cleaning stale references, and revealing storage

### Changed

- Updated public DMG installer
- Settings now drive clipboard behavior instead of relying on hardcoded defaults

### Notes

- If macOS blocks the app on first launch, remove quarantine with:

```bash
xattr -dr com.apple.quarantine /Applications/ClipSpot.app
```
