//
//  SettingsGeneralViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 27.11.24.
//

import AppKit
import Sparkle

class SettingsGeneralViewController: NSViewController {
    
    // MARK: VARS
    @objc let defaults: UserDefaults = .standard
    @objc let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    private weak var beatCountdownInfoButton: NSButton?

    // MARK: OUTLETS
    @IBOutlet weak var ddlbAppearance: NSComboBox!
    @IBOutlet weak var ddlbViewAfterSongLoad: NSComboBox!
    @IBOutlet weak var btnShowBeatCountdown: NSButton!

    // MARK: ACTIONS
    @IBAction func handleMonoChanged(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("monoChanged"), object: nil)
    }

    @IBAction func handleSleepPreventionChanged(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("preventSystemSleepChanged"), object: nil)
    }

    @objc func handleBeatCountdownInfo(_ sender: NSButton) {
        let text = NSLocalizedString("beatCountdownTooltip", bundle: Bundle.main, comment: "")

        let label = NSTextField(wrappingLabelWithString: text)
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.preferredMaxLayoutWidth = 260

        let popover = NSPopover()
        let vc = NSViewController()
        vc.view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 1))
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: -12),
        ])
        popover.contentViewController = vc
        popover.behavior = .transient
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
    }

    // MARK: View overrides
    override var preferredContentSize: NSSize {
        get { NSSize(width: 804, height: 454) }
        set { }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.ddlbAppearance.selectItem(at: Settings.appearance)
        self.ddlbViewAfterSongLoad.selectItem(at: Settings.viewAfterSongLoad)

        let info = NSButton(frame: NSRect(x: NSMaxX(btnShowBeatCountdown.frame) + 4,
                                         y: btnShowBeatCountdown.frame.origin.y - 2,
                                         width: 21, height: 21))
        info.bezelStyle = .helpButton
        info.title = ""
        info.toolTip = NSLocalizedString("beatCountdownTooltip", bundle: Bundle.main, comment: "")
        info.target = self
        info.action = #selector(handleBeatCountdownInfo(_:))
        btnShowBeatCountdown.superview?.addSubview(info)
        beatCountdownInfoButton = info
    }
}

extension SettingsGeneralViewController : NSComboBoxDelegate, NSComboBoxDataSource {
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        if comboBox.identifier?.rawValue == "cbApperance" {
            return 3 //Dark, Light, System
        } else if comboBox.identifier?.rawValue == "cbViewAfterSongLoad" {
            return 3 //Empty, Positions, PDF
        }

        return 0
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if comboBox.identifier?.rawValue == "cbApperance" {
            switch index {
                case 0:
                    return NSLocalizedString("systemAppearance", bundle: Bundle.main, comment: "") as NSString
                case 1:
                    return NSLocalizedString("darkAppearance", bundle: Bundle.main, comment: "") as NSString
                case 2:
                    return NSLocalizedString("lightAppearance", bundle: Bundle.main, comment: "") as NSString
                default:
                    return NSString(string: "")
            }
        } else if comboBox.identifier?.rawValue == "cbViewAfterSongLoad" {
            switch index {
                case 0:
                    return NSLocalizedString("viewAfterSongLoadFileList", bundle: Bundle.main, comment: "") as NSString
                case 1:
                    return NSLocalizedString("viewAfterSongLoadPositions", bundle: Bundle.main, comment: "") as NSString
                case 2:
                    return NSLocalizedString("viewAfterSongLoadPDF", bundle: Bundle.main, comment: "") as NSString
                default:
                    return NSString(string: "")
            }
        }

        return NSString(string: "")
        
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let uiElement: NSControl = notification.object as! NSControl
        if uiElement.identifier?.rawValue == "cbApperance" {
            UserDefaults.standard.set(self.ddlbAppearance.indexOfSelectedItem, forKey: UserDefaults.Keys.prefAppearance.rawValue)
        } else if uiElement.identifier?.rawValue == "cbViewAfterSongLoad" {
            UserDefaults.standard.set(self.ddlbViewAfterSongLoad.indexOfSelectedItem, forKey: UserDefaults.Keys.prefViewAfterSongLoad.rawValue)
        }

    }
}
