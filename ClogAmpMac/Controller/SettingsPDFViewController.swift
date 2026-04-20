//
//  SettingsPDFViewController.swift
//  ClogAmpSwift
//

import AppKit
import WebKit

class SettingsPDFViewController: NSViewController {

    // MARK: - Controls

    private let fontPopUp         = NSPopUpButton()
    private let titleSizeStepper  = NSStepper()
    private let titleSizeField    = NSTextField()
    private let artistSizeStepper = NSStepper()
    private let artistSizeField   = NSTextField()
    private let subheaderSizeStepper = NSStepper()
    private let subheaderSizeField   = NSTextField()
    private let nameSizeStepper   = NSStepper()
    private let nameSizeField     = NSTextField()
    private let commentSizeStepper = NSStepper()
    private let commentSizeField   = NSTextField()
    private let paddingStepper    = NSStepper()
    private let paddingField      = NSTextField()
    private let spacingStepper    = NSStepper()
    private let spacingField      = NSTextField()
    private let resetButton = NSButton(title: NSLocalizedString("pdfResetDefaults", bundle: Bundle.main, comment: ""), target: nil, action: nil)

    private let previewWebView    = WKWebView()

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 950, height: 540))
    }

    override var preferredContentSize: NSSize {
        get { NSSize(width: 950, height: 540) }
        set { }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        loadValues()
    }

    // MARK: - UI Construction

    private func buildUI() {
        // Font family
        fontPopUp.addItems(withTitles: Settings.pdfAvailableFonts)
        fontPopUp.target = self
        fontPopUp.action = #selector(fontChanged)

        configureStepper(titleSizeStepper,  field: titleSizeField,  min: 0.5, max: 6.0, increment: 0.1)
        configureStepper(artistSizeStepper, field: artistSizeField, min: 0.5, max: 6.0, increment: 0.1)
        configureStepper(subheaderSizeStepper, field: subheaderSizeField, min: 0.5, max: 4.0, increment: 0.1)
        configureStepper(nameSizeStepper,   field: nameSizeField,   min: 0.5, max: 4.0, increment: 0.1)
        configureStepper(commentSizeStepper, field: commentSizeField, min: 0.5, max: 4.0, increment: 0.1)
        configureStepper(paddingStepper,    field: paddingField,    min: 0.0, max: 3.0, increment: 0.05)
        configureStepper(spacingStepper,    field: spacingField,    min: 0,   max: 10,  increment: 0.1)

        spacingStepper.increment = 0.1
        spacingField.formatter = {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.minimumFractionDigits = 1
            f.maximumFractionDigits = 1
            return f
        }()

        resetButton.target = self
        resetButton.action = #selector(resetToDefaults)

        // Left panel: controls
        let controlsPanel = NSView()
        controlsPanel.translatesAutoresizingMaskIntoConstraints = false

        let rows: [(String, NSView, NSView)] = [
            (NSLocalizedString("pdfFont",          bundle: Bundle.main, comment: ""), fontPopUp,            NSView()),
            (NSLocalizedString("pdfTitleSize",     bundle: Bundle.main, comment: ""), titleSizeField,       titleSizeStepper),
            (NSLocalizedString("pdfArtistSize",    bundle: Bundle.main, comment: ""), artistSizeField,      artistSizeStepper),
            (NSLocalizedString("pdfSubheaderSize", bundle: Bundle.main, comment: ""), subheaderSizeField,   subheaderSizeStepper),
            (NSLocalizedString("pdfNameSize",      bundle: Bundle.main, comment: ""), nameSizeField,        nameSizeStepper),
            (NSLocalizedString("pdfCommentSize",   bundle: Bundle.main, comment: ""), commentSizeField,     commentSizeStepper),
            (NSLocalizedString("pdfCellPadding",   bundle: Bundle.main, comment: ""), paddingField,         paddingStepper),
            (NSLocalizedString("pdfHeaderSpacing", bundle: Bundle.main, comment: ""), spacingField,         spacingStepper),
        ]

        var previousAnchor = controlsPanel.topAnchor
        let labelWidth: CGFloat = 160

        for (label, control, secondary) in rows {
            let lbl = NSTextField(labelWithString: label)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            control.translatesAutoresizingMaskIntoConstraints = false
            secondary.translatesAutoresizingMaskIntoConstraints = false

            controlsPanel.addSubview(lbl)
            controlsPanel.addSubview(control)
            if secondary.superview == nil { controlsPanel.addSubview(secondary) }

            NSLayoutConstraint.activate([
                lbl.leadingAnchor.constraint(equalTo: controlsPanel.leadingAnchor, constant: 20),
                lbl.widthAnchor.constraint(equalToConstant: labelWidth),
                lbl.centerYAnchor.constraint(equalTo: control.centerYAnchor),

                control.leadingAnchor.constraint(equalTo: lbl.trailingAnchor, constant: 8),
                control.topAnchor.constraint(equalTo: previousAnchor, constant: 16),
            ])

            if secondary is NSStepper {
                NSLayoutConstraint.activate([
                    secondary.leadingAnchor.constraint(equalTo: control.trailingAnchor, constant: 4),
                    secondary.centerYAnchor.constraint(equalTo: control.centerYAnchor),
                    control.widthAnchor.constraint(equalToConstant: 60),
                ])
            } else {
                // font popup — stretch to fill panel
                NSLayoutConstraint.activate([
                    control.trailingAnchor.constraint(equalTo: controlsPanel.trailingAnchor, constant: -20),
                ])
            }

            previousAnchor = control.bottomAnchor
        }

        resetButton.translatesAutoresizingMaskIntoConstraints = false
        controlsPanel.addSubview(resetButton)
        NSLayoutConstraint.activate([
            resetButton.topAnchor.constraint(equalTo: previousAnchor, constant: 24),
            resetButton.trailingAnchor.constraint(equalTo: controlsPanel.trailingAnchor, constant: -20),
        ])

        // Right panel: preview
        previewWebView.translatesAutoresizingMaskIntoConstraints = false

        let previewBorder = NSBox()
        previewBorder.boxType = .custom
        previewBorder.borderColor = NSColor.separatorColor
        previewBorder.borderWidth = 1
        previewBorder.cornerRadius = 4
        previewBorder.fillColor = .white
        previewBorder.translatesAutoresizingMaskIntoConstraints = false
        previewBorder.addSubview(previewWebView)

        let previewLabel = NSTextField(labelWithString: NSLocalizedString("pdfPreview", bundle: Bundle.main, comment: ""))
        previewLabel.font = NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
        previewLabel.textColor = .secondaryLabelColor
        previewLabel.translatesAutoresizingMaskIntoConstraints = false

        // Assemble root view
        view.addSubview(controlsPanel)
        view.addSubview(previewLabel)
        view.addSubview(previewBorder)

        NSLayoutConstraint.activate([
            // Web view fills the border box
            previewWebView.topAnchor.constraint(equalTo: previewBorder.topAnchor, constant: 4),
            previewWebView.leadingAnchor.constraint(equalTo: previewBorder.leadingAnchor, constant: 4),
            previewWebView.trailingAnchor.constraint(equalTo: previewBorder.trailingAnchor, constant: -4),
            previewWebView.bottomAnchor.constraint(equalTo: previewBorder.bottomAnchor, constant: -4),

            // Controls panel: left side, fixed width
            controlsPanel.topAnchor.constraint(equalTo: view.topAnchor),
            controlsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            controlsPanel.widthAnchor.constraint(equalToConstant: 300),

            // Preview label above the border
            previewLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            previewLabel.leadingAnchor.constraint(equalTo: controlsPanel.trailingAnchor, constant: 16),

            // Border box: right of controls panel
            previewBorder.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 6),
            previewBorder.leadingAnchor.constraint(equalTo: controlsPanel.trailingAnchor, constant: 16),
            previewBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewBorder.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
        ])
    }

    private func configureStepper(_ stepper: NSStepper, field: NSTextField, min: Double, max: Double, increment: Double) {
        stepper.minValue = min
        stepper.maxValue = max
        stepper.increment = increment
        stepper.valueWraps = false
        stepper.target = self
        stepper.action = #selector(stepperChanged(_:))

        field.isEditable = true
        field.isSelectable = true
        field.formatter = {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.minimumFractionDigits = increment < 1 ? 2 : 0
            f.maximumFractionDigits = increment < 1 ? 2 : 0
            return f
        }()
        field.delegate = self
    }

    // MARK: - Preview

    private func buildPreviewHTML() -> String {
        let font          = fontPopUp.titleOfSelectedItem ?? "Arial"
        let titleSize     = titleSizeStepper.doubleValue
        let artistSize    = artistSizeStepper.doubleValue
        let subheaderSize = subheaderSizeStepper.doubleValue
        let nameSize      = nameSizeStepper.doubleValue
        let commentSize   = commentSizeStepper.doubleValue
        let cellPadding   = paddingStepper.doubleValue
        let headerSpacing = spacingStepper.doubleValue

        struct PreviewPosition { let name: String; let comment: String }
        let songTitle: String
        let songArtist: String
        let songDuration: String
        let positions: [PreviewPosition]

        if let song = PlayerAudioEngine.shared.song {
            songTitle    = song.title
            songArtist   = song.artist
            songDuration = song.getValueAsString("duration")
            positions    = song.getPositions().map { PreviewPosition(name: $0.name, comment: $0.comment) }
        } else {
            songTitle    = "Song Title"
            songArtist   = "Artist Name"
            songDuration = "3:45"
            positions    = [
                PreviewPosition(name: "Intro",  comment: "Opening section"),
                PreviewPosition(name: "Verse",  comment: "Main verse"),
                PreviewPosition(name: "Chorus", comment: "Big chorus"),
            ]
        }

        var html = ""
        html += "<style>"
        html += "  div { display:inline; font-family: '\(font)'; }"
        html += "  table, td { font-family: '\(font)'; border: 0px solid black; border-collapse: collapse; }"
        html += "  td { padding: \(cellPadding)rem; vertical-align: top; }"
        html += "  .center { display: table; margin-right: auto; margin-left: auto; }"
        html += "  .bold { font-weight: bold; }"
        html += "  .nowrap { white-space: nowrap; }"
        html += "</style>"

        html += "<div class='center'>"
        html += "  <div style='font-size: \(titleSize)rem'>\(songTitle)</div>&nbsp;<div style='font-size: \(artistSize)rem'>\(songArtist)</div>"
        html += "</div>"
        html += "<div class='center' style='font-size: \(subheaderSize)rem'>\(songDuration)</div>"
        html += "<div style='display: block; margin-bottom: \(headerSpacing)rem'></div>"

        html += "<table>"
        for pos in positions {
            html += "<tr>"
            html += "  <td class='bold nowrap' style='font-size: \(nameSize)rem'>\(pos.name)</td>"
            html += "  <td style='font-size: \(commentSize)rem'>\(pos.comment)</td>"
            html += "</tr>"
        }
        html += "</table>"

        return html
    }

    private func updatePreview() {
        previewWebView.loadHTMLString(buildPreviewHTML(), baseURL: nil)
    }

    // MARK: - Load / Save

    private func loadValues() {
        fontPopUp.selectItem(withTitle: Settings.pdfFontFamily)
        if fontPopUp.indexOfSelectedItem == -1 { fontPopUp.selectItem(at: 0) }

        set(stepper: titleSizeStepper,     field: titleSizeField,     value: Settings.pdfTitleSize)
        set(stepper: artistSizeStepper,    field: artistSizeField,    value: Settings.pdfArtistSize)
        set(stepper: subheaderSizeStepper, field: subheaderSizeField, value: Settings.pdfSubheaderSize)
        set(stepper: nameSizeStepper,      field: nameSizeField,      value: Settings.pdfPositionNameSize)
        set(stepper: commentSizeStepper,   field: commentSizeField,   value: Settings.pdfCommentSize)
        set(stepper: paddingStepper,       field: paddingField,       value: Settings.pdfCellPadding)
        set(stepper: spacingStepper,       field: spacingField,       value: Settings.pdfHeaderSpacing)

        updatePreview()
    }

    private func set(stepper: NSStepper, field: NSTextField, value: Double) {
        stepper.doubleValue = value
        field.doubleValue   = value
    }

    private func saveAll() {
        let d = UserDefaults.standard
        d.set(fontPopUp.titleOfSelectedItem,        forKey: UserDefaults.Keys.pdfFontFamily.rawValue)
        d.set(titleSizeStepper.doubleValue,         forKey: UserDefaults.Keys.pdfTitleSize.rawValue)
        d.set(artistSizeStepper.doubleValue,        forKey: UserDefaults.Keys.pdfArtistSize.rawValue)
        d.set(subheaderSizeStepper.doubleValue,     forKey: UserDefaults.Keys.pdfSubheaderSize.rawValue)
        d.set(nameSizeStepper.doubleValue,          forKey: UserDefaults.Keys.pdfPositionNameSize.rawValue)
        d.set(commentSizeStepper.doubleValue,       forKey: UserDefaults.Keys.pdfCommentSize.rawValue)
        d.set(paddingStepper.doubleValue,           forKey: UserDefaults.Keys.pdfCellPadding.rawValue)
        d.set(spacingStepper.doubleValue,           forKey: UserDefaults.Keys.pdfHeaderSpacing.rawValue)
    }

    // MARK: - Actions

    @objc private func fontChanged() {
        UserDefaults.standard.set(fontPopUp.titleOfSelectedItem, forKey: UserDefaults.Keys.pdfFontFamily.rawValue)
        updatePreview()
    }

    @objc private func stepperChanged(_ sender: NSStepper) {
        switch sender {
        case titleSizeStepper:     set(stepper: titleSizeStepper,     field: titleSizeField,     value: sender.doubleValue)
        case artistSizeStepper:    set(stepper: artistSizeStepper,    field: artistSizeField,    value: sender.doubleValue)
        case subheaderSizeStepper: set(stepper: subheaderSizeStepper, field: subheaderSizeField, value: sender.doubleValue)
        case nameSizeStepper:      set(stepper: nameSizeStepper,      field: nameSizeField,      value: sender.doubleValue)
        case commentSizeStepper:   set(stepper: commentSizeStepper,   field: commentSizeField,   value: sender.doubleValue)
        case paddingStepper:       set(stepper: paddingStepper,       field: paddingField,       value: sender.doubleValue)
        case spacingStepper:       set(stepper: spacingStepper,       field: spacingField,       value: sender.doubleValue)
        default: break
        }
        saveAll()
        updatePreview()
    }

    @objc private func resetToDefaults() {
        let d = UserDefaults.standard
        [UserDefaults.Keys.pdfFontFamily,
         UserDefaults.Keys.pdfTitleSize,
         UserDefaults.Keys.pdfArtistSize,
         UserDefaults.Keys.pdfSubheaderSize,
         UserDefaults.Keys.pdfPositionNameSize,
         UserDefaults.Keys.pdfCommentSize,
         UserDefaults.Keys.pdfCellPadding,
         UserDefaults.Keys.pdfHeaderSpacing].forEach { d.removeObject(forKey: $0.rawValue) }

        loadValues()
    }
}

// MARK: - NSTextFieldDelegate (field → stepper sync)

extension SettingsPDFViewController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        let value = field.doubleValue

        switch field {
        case titleSizeField:     titleSizeStepper.doubleValue     = value
        case artistSizeField:    artistSizeStepper.doubleValue    = value
        case subheaderSizeField: subheaderSizeStepper.doubleValue = value
        case nameSizeField:      nameSizeStepper.doubleValue      = value
        case commentSizeField:   commentSizeStepper.doubleValue   = value
        case paddingField:       paddingStepper.doubleValue       = value
        case spacingField:       spacingStepper.doubleValue       = value
        default: break
        }
        saveAll()
        updatePreview()
    }
}
