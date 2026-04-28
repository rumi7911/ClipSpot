import AppKit

enum ClipboardShelfKeyboardAction: Equatable {
    case moveUp
    case moveDown
    case copySelected
    case close
    case focusSearch

    static func action(
        keyCode: UInt16,
        charactersIgnoringModifiers: String?,
        modifierFlags: NSEvent.ModifierFlags
    ) -> ClipboardShelfKeyboardAction? {
        let commandModifiers = modifierFlags.intersection([.command, .option, .control, .shift])

        if commandModifiers == .command,
           charactersIgnoringModifiers?.lowercased() == "f" {
            return .focusSearch
        }

        guard commandModifiers.isEmpty else {
            return nil
        }

        switch keyCode {
        case 126:
            return .moveUp
        case 125:
            return .moveDown
        case 36, 76:
            return .copySelected
        case 53:
            return .close
        default:
            return nil
        }
    }
}
