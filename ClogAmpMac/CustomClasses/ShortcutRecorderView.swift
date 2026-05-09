//
//  ShortcutRecorderView.swift
//  ClogAmpSwift
//

import AppKit

class ShortcutRecorderView: NSView {

    var shortcut: KeyboardShortcut? { didSet { updateDisplay() } }
    var onChange: ((KeyboardShortcut?) -> Void)?

    private var isRecording = false
    private let label = NSTextField(labelWithString: "")

    // Key codes that are pure modifier keys — don't record these
    private static let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 5

        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.alignment = .center
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
        ])

        updateStyle()
        updateDisplay()
    }

    // MARK: - State

    private func startRecording() {
        isRecording = true
        updateDisplay()
        updateStyle()
    }

    private func stopRecording() {
        isRecording = false
        updateDisplay()
        updateStyle()
    }

    private func updateDisplay() {
        if isRecording {
            label.stringValue = NSLocalizedString("shortcutRecorder.recording", comment: "")
            label.textColor = .secondaryLabelColor
        } else if let shortcut {
            label.stringValue = shortcut.displayString
            label.textColor = .labelColor
        } else {
            label.stringValue = "–"
            label.textColor = .tertiaryLabelColor
        }
    }

    private func updateStyle() {
        if isRecording {
            layer?.borderWidth = 2
            layer?.borderColor = NSColor.controlAccentColor.cgColor
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.08).cgColor
        } else {
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
    }

    // MARK: - First Responder

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { updateStyle() }
        return result
    }

    override func resignFirstResponder() -> Bool {
        if isRecording { stopRecording() }
        let result = super.resignFirstResponder()
        updateStyle()
        return result
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        if window?.firstResponder === self {
            isRecording ? stopRecording() : startRecording()
        } else {
            window?.makeFirstResponder(self)
            startRecording()
        }
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 { // Escape — cancel
            stopRecording()
            return
        }

        if event.keyCode == 51 || event.keyCode == 117 { // Delete — clear shortcut
            shortcut = nil
            onChange?(nil)
            stopRecording()
            return
        }

        if Self.modifierKeyCodes.contains(event.keyCode) { return }

        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        let char = event.charactersIgnoringModifiers?.lowercased() ?? ""
        let recorded = KeyboardShortcut(keyCode: event.keyCode, modifierFlags: mods, character: char)
        shortcut = recorded
        onChange?(recorded)
        stopRecording()
    }

    // MARK: - Appearance

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateStyle()
    }
}
