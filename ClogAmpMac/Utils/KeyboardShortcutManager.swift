//
//  KeyboardShortcutManager.swift
//  ClogAmpSwift
//

import AppKit

// MARK: - Model

struct KeyboardShortcut: Codable, Equatable {
    let keyCode: UInt16
    let modifierFlags: UInt  // NSEvent.ModifierFlags device-independent raw value
    let character: String    // used for NSMenuItem.keyEquivalent; "" for keyDown-only shortcuts

    init(keyCode: UInt16, modifierFlags: UInt, character: String = "") {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.character = character
    }

    // Backward-compatible decoding: old stored shortcuts have no 'character' field
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        keyCode       = try c.decode(UInt16.self, forKey: .keyCode)
        modifierFlags = try c.decode(UInt.self,   forKey: .modifierFlags)
        character     = try c.decodeIfPresent(String.self, forKey: .character) ?? ""
    }

    func matches(_ event: NSEvent) -> Bool {
        event.keyCode == keyCode &&
        event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue == modifierFlags
    }

    func matchesShifted(_ event: NSEvent) -> Bool {
        guard event.keyCode == keyCode else { return false }
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var expected = NSEvent.ModifierFlags(rawValue: modifierFlags)
        expected.insert(.shift)
        return mods == expected
    }

    /// The character to put in NSMenuItem.keyEquivalent.
    /// Some key codes need a fixed string regardless of what was recorded.
    var menuCharacter: String {
        switch keyCode {
        case 51:  return "\u{08}" // backspace / Delete key
        case 117: return "\u{7f}" // forward delete
        default:  return character
        }
    }

    var displayString: String {
        var parts: [String] = []
        let mods = NSEvent.ModifierFlags(rawValue: modifierFlags)
        if mods.contains(.control) { parts.append("⌃") }
        if mods.contains(.option)  { parts.append("⌥") }
        if mods.contains(.shift)   { parts.append("⇧") }
        if mods.contains(.command) { parts.append("⌘") }
        parts.append(Self.keyName(for: keyCode, character: character))
        return parts.joined()
    }

    static func keyName(for keyCode: UInt16, character: String = "") -> String {
        // Keys whose display name is fixed regardless of keyboard layout
        let specials: [UInt16: String] = [
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
            65: "Num.", 67: "Num*", 69: "Num+", 71: "⌧", 75: "Num/", 76: "Num↩",
            78: "Num-", 81: "Num=",
            82: "Num0", 83: "Num1", 84: "Num2", 85: "Num3", 86: "Num4",
            87: "Num5", 88: "Num6", 89: "Num7", 91: "Num8", 92: "Num9",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
            103: "F11", 105: "F13", 106: "F16", 107: "F14", 109: "F10",
            111: "F12", 113: "F15", 114: "⌦", 115: "↖", 116: "⇞",
            117: "⌦", 118: "F4", 119: "↘", 120: "F2", 121: "⇟",
            122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        if let name = specials[keyCode] { return name }
        // For regular keys use the recorded character so the display matches the active layout
        if !character.isEmpty { return character.uppercased() }
        // Fallback: US-layout names for key-down-only shortcuts that have no stored character
        let usLayout: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",
            43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 50: "`",
        ]
        return usLayout[keyCode] ?? "(\(keyCode))"
    }
}

// MARK: - Actions

enum ShortcutAction: String, CaseIterable {

    // Playback — keyDown handlers (playPause also controls Player > Pause menu item)
    case playPause        = "playPause"
    case loadSong         = "loadSong"
    case playPosition     = "playPosition"
    case jumpToPosition1  = "jumpToPosition1"
    case jumpToPosition2  = "jumpToPosition2"
    case jumpToPosition3  = "jumpToPosition3"
    case jumpToPosition4  = "jumpToPosition4"
    case jumpToPosition5  = "jumpToPosition5"
    case jumpToPosition6  = "jumpToPosition6"
    case jumpToPosition7  = "jumpToPosition7"
    case jumpToPosition8  = "jumpToPosition8"
    case jumpToPosition9  = "jumpToPosition9"
    case jumpToPosition10 = "jumpToPosition10"

    // Menu — File
    case menuOpenFolder   = "menuOpenFolder"
    case menuSaveSong     = "menuSaveSong"
    case menuGeneratePDF  = "menuGeneratePDF"

    // Menu — Edit
    case menuAddPosition    = "menuAddPosition"
    case menuRemovePosition = "menuRemovePosition"

    // Menu — Tools
    case menuFilter            = "menuFilter"
    case menuDetermineBPM      = "menuDetermineBPM"
    case menuDetermineBPMClick = "menuDetermineBPMClick"
    case menuReloadList        = "menuReloadList"
    case menuShowTime     = "menuShowTime"
    case menuCountdown    = "menuCountdown"
    case menuHistory      = "menuHistory"
    case menuPlaylists    = "menuPlaylists"

    // Menu — Player
    case menuPlay         = "menuPlay"
    case menuStop         = "menuStop"
    case menuSkipForward  = "menuSkipForward"
    case menuSkipBack     = "menuSkipBack"
    case menuSpeedInc1    = "menuSpeedInc1"
    case menuSpeedInc5    = "menuSpeedInc5"
    case menuSpeedDec1    = "menuSpeedDec1"
    case menuSpeedDec5    = "menuSpeedDec5"
    case menuResetSpeed   = "menuResetSpeed"
    case menuEQ           = "menuEQ"

    var displayName: String {
        switch self {
        case .playPause:          return NSLocalizedString("shortcut.playPause",          comment: "")
        case .loadSong:           return NSLocalizedString("shortcut.loadSong",           comment: "")
        case .playPosition:       return NSLocalizedString("shortcut.playPosition",       comment: "")
        case .jumpToPosition1:    return NSLocalizedString("shortcut.jumpToPosition1",    comment: "")
        case .jumpToPosition2:    return NSLocalizedString("shortcut.jumpToPosition2",    comment: "")
        case .jumpToPosition3:    return NSLocalizedString("shortcut.jumpToPosition3",    comment: "")
        case .jumpToPosition4:    return NSLocalizedString("shortcut.jumpToPosition4",    comment: "")
        case .jumpToPosition5:    return NSLocalizedString("shortcut.jumpToPosition5",    comment: "")
        case .jumpToPosition6:    return NSLocalizedString("shortcut.jumpToPosition6",    comment: "")
        case .jumpToPosition7:    return NSLocalizedString("shortcut.jumpToPosition7",    comment: "")
        case .jumpToPosition8:    return NSLocalizedString("shortcut.jumpToPosition8",    comment: "")
        case .jumpToPosition9:    return NSLocalizedString("shortcut.jumpToPosition9",    comment: "")
        case .jumpToPosition10:   return NSLocalizedString("shortcut.jumpToPosition10",   comment: "")
        case .menuOpenFolder:     return NSLocalizedString("shortcut.menuOpenFolder",     comment: "")
        case .menuSaveSong:       return NSLocalizedString("shortcut.menuSaveSong",       comment: "")
        case .menuGeneratePDF:    return NSLocalizedString("shortcut.menuGeneratePDF",    comment: "")
        case .menuAddPosition:    return NSLocalizedString("shortcut.menuAddPosition",    comment: "")
        case .menuRemovePosition: return NSLocalizedString("shortcut.menuRemovePosition", comment: "")
        case .menuFilter:            return NSLocalizedString("shortcut.menuFilter",            comment: "")
        case .menuDetermineBPM:      return NSLocalizedString("shortcut.menuDetermineBPM",      comment: "")
        case .menuDetermineBPMClick: return NSLocalizedString("shortcut.menuDetermineBPMClick", comment: "")
        case .menuReloadList:     return NSLocalizedString("shortcut.menuReloadList",     comment: "")
        case .menuShowTime:       return NSLocalizedString("shortcut.menuShowTime",       comment: "")
        case .menuCountdown:      return NSLocalizedString("shortcut.menuCountdown",      comment: "")
        case .menuHistory:        return NSLocalizedString("shortcut.menuHistory",        comment: "")
        case .menuPlaylists:      return NSLocalizedString("shortcut.menuPlaylists",      comment: "")
        case .menuPlay:           return NSLocalizedString("shortcut.menuPlay",           comment: "")
        case .menuStop:           return NSLocalizedString("shortcut.menuStop",           comment: "")
        case .menuSkipForward:    return NSLocalizedString("shortcut.menuSkipForward",    comment: "")
        case .menuSkipBack:       return NSLocalizedString("shortcut.menuSkipBack",       comment: "")
        case .menuSpeedInc1:      return NSLocalizedString("shortcut.menuSpeedInc1",      comment: "")
        case .menuSpeedInc5:      return NSLocalizedString("shortcut.menuSpeedInc5",      comment: "")
        case .menuSpeedDec1:      return NSLocalizedString("shortcut.menuSpeedDec1",      comment: "")
        case .menuSpeedDec5:      return NSLocalizedString("shortcut.menuSpeedDec5",      comment: "")
        case .menuResetSpeed:     return NSLocalizedString("shortcut.menuResetSpeed",     comment: "")
        case .menuEQ:             return NSLocalizedString("shortcut.menuEQ",             comment: "")
        }
    }

    /// Storyboard tag used to locate the corresponding NSMenuItem in NSApp.mainMenu.
    /// NSMenu.item(withTag:) searches recursively, so nesting depth doesn't matter.
    var menuTag: Int? {
        switch self {
        case .playPause:             return 1015
        case .menuOpenFolder:        return 1001
        case .menuSaveSong:          return 1002
        case .menuGeneratePDF:       return 1003
        case .menuAddPosition:       return 1004
        case .menuRemovePosition:    return 1005
        case .menuFilter:            return 1006
        case .menuDetermineBPM:      return 1007
        case .menuDetermineBPMClick: return 1008
        case .menuReloadList:        return 1009
        case .menuShowTime:          return 1010
        case .menuCountdown:         return 1011
        case .menuHistory:           return 1012
        case .menuPlaylists:         return 1013
        case .menuPlay:              return 1014
        case .menuStop:              return 1016
        case .menuSkipForward:       return 1017
        case .menuSkipBack:          return 1018
        case .menuSpeedInc1:         return 1019
        case .menuSpeedInc5:         return 1020
        case .menuSpeedDec1:         return 1021
        case .menuSpeedDec5:         return 1022
        case .menuResetSpeed:        return 1023
        case .menuEQ:                return 1024
        default:                     return nil
        }
    }

    var defaultShortcut: KeyboardShortcut? {
        let cmd   = NSEvent.ModifierFlags.command.rawValue
        let shift = NSEvent.ModifierFlags.shift.rawValue
        switch self {
        case .playPause:          return KeyboardShortcut(keyCode: 49, modifierFlags: 0,     character: " ")
        case .loadSong:           return KeyboardShortcut(keyCode: 36, modifierFlags: 0)
        case .playPosition:       return KeyboardShortcut(keyCode: 36, modifierFlags: 0)
        case .jumpToPosition1:    return KeyboardShortcut(keyCode: 18, modifierFlags: 0)
        case .jumpToPosition2:    return KeyboardShortcut(keyCode: 19, modifierFlags: 0)
        case .jumpToPosition3:    return KeyboardShortcut(keyCode: 20, modifierFlags: 0)
        case .jumpToPosition4:    return KeyboardShortcut(keyCode: 21, modifierFlags: 0)
        case .jumpToPosition5:    return KeyboardShortcut(keyCode: 23, modifierFlags: 0)
        case .jumpToPosition6:    return KeyboardShortcut(keyCode: 22, modifierFlags: 0)
        case .jumpToPosition7:    return KeyboardShortcut(keyCode: 26, modifierFlags: 0)
        case .jumpToPosition8:    return KeyboardShortcut(keyCode: 28, modifierFlags: 0)
        case .jumpToPosition9:    return KeyboardShortcut(keyCode: 25, modifierFlags: 0)
        case .jumpToPosition10:   return KeyboardShortcut(keyCode: 29, modifierFlags: 0)
        case .menuOpenFolder:     return KeyboardShortcut(keyCode: 31, modifierFlags: cmd,   character: "o")
        case .menuSaveSong:       return KeyboardShortcut(keyCode: 1,  modifierFlags: cmd,   character: "s")
        case .menuGeneratePDF:    return KeyboardShortcut(keyCode: 35, modifierFlags: cmd,   character: "p")
        case .menuAddPosition:    return KeyboardShortcut(keyCode: 0,  modifierFlags: 0,     character: "a")
        case .menuRemovePosition: return KeyboardShortcut(keyCode: 51, modifierFlags: 0,     character: "\u{08}")
        case .menuFilter:         return KeyboardShortcut(keyCode: 3,  modifierFlags: cmd,   character: "f")
        case .menuDetermineBPM:      return KeyboardShortcut(keyCode: 11, modifierFlags: cmd, character: "b")
        case .menuDetermineBPMClick: return nil
        case .menuReloadList:     return KeyboardShortcut(keyCode: 15, modifierFlags: cmd,   character: "r")
        case .menuShowTime:       return KeyboardShortcut(keyCode: 17, modifierFlags: cmd,   character: "t")
        case .menuCountdown:      return KeyboardShortcut(keyCode: 2,  modifierFlags: cmd,   character: "d")
        case .menuHistory:        return KeyboardShortcut(keyCode: 4,  modifierFlags: cmd,   character: "h")
        case .menuPlaylists:      return KeyboardShortcut(keyCode: 37, modifierFlags: cmd,   character: "l")
        case .menuPlay:           return KeyboardShortcut(keyCode: 35, modifierFlags: 0,     character: "p")
        case .menuStop:           return KeyboardShortcut(keyCode: 1,  modifierFlags: 0,     character: "s")
        case .menuSkipForward:    return KeyboardShortcut(keyCode: 3,  modifierFlags: 0,     character: "f")
        case .menuSkipBack:       return KeyboardShortcut(keyCode: 11, modifierFlags: 0,     character: "b")
        case .menuSpeedInc1:      return KeyboardShortcut(keyCode: 24, modifierFlags: 0,     character: "+")
        case .menuSpeedInc5:      return KeyboardShortcut(keyCode: 24, modifierFlags: shift, character: "+")
        case .menuSpeedDec1:      return KeyboardShortcut(keyCode: 27, modifierFlags: 0,     character: "-")
        case .menuSpeedDec5:      return KeyboardShortcut(keyCode: 27, modifierFlags: shift, character: "-")
        case .menuResetSpeed:     return KeyboardShortcut(keyCode: 45, modifierFlags: 0,     character: "n")
        case .menuEQ:             return KeyboardShortcut(keyCode: 14, modifierFlags: cmd,   character: "e")
        }
    }
}

// MARK: - Manager

class KeyboardShortcutManager {

    static let shared = KeyboardShortcutManager()
    static let changed = Notification.Name("keyboardShortcutsChanged")

    private static let defaultsKey = "prefKeyboardShortcuts"
    private var overrides: [String: KeyboardShortcut] = [:]

    private init() { load() }

    func shortcut(for action: ShortcutAction) -> KeyboardShortcut? {
        overrides[action.rawValue] ?? action.defaultShortcut
    }

    func setShortcut(_ shortcut: KeyboardShortcut?, for action: ShortcutAction) {
        if let shortcut {
            overrides[action.rawValue] = shortcut
        } else {
            overrides.removeValue(forKey: action.rawValue)
        }
        save()
        NotificationCenter.default.post(name: Self.changed, object: nil)
    }

    func resetToDefaults() {
        overrides = [:]
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
        NotificationCenter.default.post(name: Self.changed, object: nil)
    }

    /// Apply all menu-bound shortcuts to the live NSApp.mainMenu.
    /// Call on the main thread after applicationDidFinishLaunching.
    func applyMenuShortcuts() {
        guard let mainMenu = NSApp.mainMenu else { return }
        for action in ShortcutAction.allCases {
            guard action.menuTag != nil else { continue }
            let id = NSUserInterfaceItemIdentifier(rawValue: action.rawValue)
            guard let item = findMenuItem(withIdentifier: id, in: mainMenu) else { continue }
            if let sc = shortcut(for: action) {
                item.keyEquivalent = sc.menuCharacter
                item.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: sc.modifierFlags)
            } else {
                item.keyEquivalent = ""
                item.keyEquivalentModifierMask = []
            }
        }
    }

    private func findMenuItem(withIdentifier id: NSUserInterfaceItemIdentifier, in menu: NSMenu) -> NSMenuItem? {
        for item in menu.items {
            if item.identifier == id { return item }
            if let sub = item.submenu, let found = findMenuItem(withIdentifier: id, in: sub) { return found }
        }
        return nil
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let decoded = try? JSONDecoder().decode([String: KeyboardShortcut].self, from: data)
        else { return }
        overrides = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(overrides) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
