//
//  SettingsShortcutsViewController.swift
//  ClogAmpSwift
//

import AppKit

class SettingsShortcutsViewController: NSViewController {

    private let scrollView  = NSScrollView()
    private let resetButton = NSButton(title: NSLocalizedString("shortcutReset.button", comment: ""), target: nil, action: nil)

    private let viewWidth: CGFloat     = 560
    private let viewHeight: CGFloat    = 560
    private let rowHeight: CGFloat     = 38
    private let sectionHeight: CGFloat = 28
    private let labelWidth: CGFloat    = 300
    private let recorderWidth: CGFloat = 140
    private let hPad: CGFloat = 24
    private let vPad: CGFloat = 16

    private static let sections: [(header: String, actions: [ShortcutAction])] = [
        (NSLocalizedString("shortcutSection.menuFile",   comment: ""), [
            .menuOpenFolder, .menuSaveSong, .menuGeneratePDF,
        ]),
        (NSLocalizedString("shortcutSection.menuEdit",   comment: ""), [
            .menuAddPosition, .menuRemovePosition,
        ]),
        (NSLocalizedString("shortcutSection.menuTools",  comment: ""), [
            .menuFilter, .menuDetermineBPM, .menuDetermineBPMClick, .menuReloadList,
            .menuShowTime, .menuCountdown, .menuHistory, .menuPlaylists,
        ]),
        (NSLocalizedString("shortcutSection.menuPlayer", comment: ""), [
            .menuPlay, .playPause, .menuStop, .menuSkipForward, .menuSkipBack,
            .menuSpeedInc1, .menuSpeedInc5, .menuSpeedDec1, .menuSpeedDec5,
            .menuResetSpeed, .menuEQ,
        ]),
        (NSLocalizedString("shortcutSection.others"  ,   comment: ""), [
            .loadSong, .playPosition,
            .jumpToPosition1, .jumpToPosition2, .jumpToPosition3, .jumpToPosition4, .jumpToPosition5,
            .jumpToPosition6, .jumpToPosition7, .jumpToPosition8, .jumpToPosition9, .jumpToPosition10,
        ]),
    ]

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: viewWidth, height: viewHeight))
    }

    override var preferredContentSize: NSSize {
        get { NSSize(width: viewWidth, height: viewHeight) }
        set { }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
    }

    // MARK: - UI

    private func buildUI() {
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetToDefaults)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resetButton)

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hPad),
            resetButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -vPad),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: resetButton.topAnchor, constant: -vPad),
        ])

        populateRows()
    }

    private func populateRows() {
        let sections     = Self.sections
        let totalRows    = sections.reduce(0) { $0 + $1.actions.count }
        let totalHeight  = CGFloat(totalRows) * rowHeight
                         + CGFloat(sections.count) * sectionHeight
                         + vPad * 2
        let docWidth     = viewWidth

        let docView = NSView(frame: NSRect(x: 0, y: 0, width: docWidth, height: totalHeight))
        var yFromTop: CGFloat = vPad

        for section in sections {
            addSectionHeader(section.header, yFromTop: yFromTop, totalHeight: totalHeight, in: docView)
            yFromTop += sectionHeight

            for (i, action) in section.actions.enumerated() {
                let yFromBottom = totalHeight - yFromTop - rowHeight
                let row = NSView(frame: NSRect(x: 0, y: yFromBottom, width: docWidth, height: rowHeight))

                if i % 2 == 0 {
                    row.wantsLayer = true
                    row.layer?.backgroundColor = NSColor.alternatingContentBackgroundColors[0].cgColor
                }

                let nameLabel = NSTextField(labelWithString: action.displayName)
                nameLabel.frame = NSRect(x: hPad, y: (rowHeight - 15) / 2, width: labelWidth, height: 15)
                nameLabel.font = .systemFont(ofSize: 12)
                row.addSubview(nameLabel)

                let recorder = ShortcutRecorderView(
                    frame: NSRect(x: docWidth - hPad - recorderWidth,
                                  y: (rowHeight - 26) / 2,
                                  width: recorderWidth, height: 26)
                )
                recorder.shortcut = KeyboardShortcutManager.shared.shortcut(for: action)
                let capturedAction = action
                recorder.onChange = { newShortcut in
                    KeyboardShortcutManager.shared.setShortcut(newShortcut, for: capturedAction)
                    DispatchQueue.main.async { KeyboardShortcutManager.shared.applyMenuShortcuts() }
                }
                row.addSubview(recorder)
                docView.addSubview(row)

                yFromTop += rowHeight
            }
        }

        scrollView.documentView = docView
        docView.scroll(NSPoint(x: 0, y: docView.bounds.height))
    }

    private func addSectionHeader(_ title: String, yFromTop: CGFloat, totalHeight: CGFloat, in docView: NSView) {
        let yFromBottom = totalHeight - yFromTop - sectionHeight
        let bg = NSView(frame: NSRect(x: 0, y: yFromBottom, width: docView.bounds.width, height: sectionHeight))
        bg.wantsLayer = true
        bg.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.15).cgColor

        let label = NSTextField(labelWithString: title.uppercased())
        label.frame = NSRect(x: hPad, y: (sectionHeight - 12) / 2, width: docView.bounds.width - hPad * 2, height: 12)
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .secondaryLabelColor
        bg.addSubview(label)
        docView.addSubview(bg)
    }

    // MARK: - Reset

    @objc private func resetToDefaults() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("shortcutReset.alertTitle",   comment: "")
        alert.informativeText = NSLocalizedString("shortcutReset.alertMessage", comment: "")
        alert.addButton(withTitle: NSLocalizedString("shortcutReset.confirm", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("shortcutReset.cancel",  comment: ""))
        alert.alertStyle = .warning
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        KeyboardShortcutManager.shared.resetToDefaults()
        DispatchQueue.main.async { KeyboardShortcutManager.shared.applyMenuShortcuts() }
        scrollView.documentView?.subviews.forEach { $0.removeFromSuperview() }
        populateRows()
    }
}
