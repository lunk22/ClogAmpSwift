//
//  SettingsPositionsViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 27.11.24.
//

import AppKit

class SettingsPositionsViewController: NSViewController {

    // MARK: VARS
    @objc let defaults: UserDefaults = .standard
    private weak var playbackOffsetInfoButton: NSButton?

    // MARK: OUTLETS
    @IBOutlet weak var ddlbAddPositionBehavior: NSComboBox!
    @IBOutlet weak var ddlbBeatsBehaviorChange: NSComboBox!
    @IBOutlet weak var ddlbPlayPositionOffset: NSComboBox!
    @IBOutlet weak var cwHighlightColor: NSColorWell!
    @IBOutlet weak var cwTextColor: NSColorWell!
    @IBOutlet weak var btnAdjustHighlightOffset: NSButton!

    // MARK: ACTIONS
    @IBAction func handleColorSelected(_ sender: Any) {
        switch sender as! NSColorWell {
            case self.cwHighlightColor:
                if let data = try? NSKeyedArchiver.archivedData(withRootObject: self.cwHighlightColor.color, requiringSecureCoding: false) {
                    UserDefaults.standard.set(data, forKey: UserDefaults.Keys.prefPositionHighlightColor.rawValue)
                }
            case self.cwTextColor:
                if let data = try? NSKeyedArchiver.archivedData(withRootObject: self.cwTextColor.color, requiringSecureCoding: false) {
                    UserDefaults.standard.set(data, forKey: UserDefaults.Keys.prefPositionTextColor.rawValue)
                }
            default:
                return
        }
    }
    
    @IBAction func handleShowBeatsChanged(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("showBeats"), object: nil)
    }

    @objc func handlePlaybackOffsetInfo(_ sender: NSButton) {
        let text = NSLocalizedString("playbackOffsetTooltip", bundle: Bundle.main, comment: "")

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
        get { NSSize(width: 804, height: 560) }
        set { }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ddlbAddPositionBehavior.selectItem(at: Settings.addPositionBehavior)
        self.ddlbBeatsBehaviorChange.selectItem(at: Settings.beatsChangeBehavior)
        self.ddlbPlayPositionOffset.selectItem(at: Settings.playPositionOffset)

        self.cwHighlightColor.color = Settings.positionHighlightColor
        self.cwTextColor.color = Settings.positionTextColor

        let info = NSButton(frame: NSRect(x: NSMaxX(btnAdjustHighlightOffset.frame) + 4,
                                         y: btnAdjustHighlightOffset.frame.origin.y - 2,
                                         width: 21, height: 21))
        info.bezelStyle = .helpButton
        info.title = ""
        info.toolTip = NSLocalizedString("playbackOffsetTooltip", bundle: Bundle.main, comment: "")
        info.target = self
        info.action = #selector(handlePlaybackOffsetInfo(_:))
        btnAdjustHighlightOffset.superview?.addSubview(info)
        playbackOffsetInfoButton = info
    }
}

extension SettingsPositionsViewController : NSComboBoxDelegate, NSComboBoxDataSource {
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        if comboBox.identifier?.rawValue == "ddlbBeatsChangeBehavior" {
            return 2 //Adjust next position, move all following positions
        } else if comboBox.identifier?.rawValue == "ddlbAddPositionBehavior" {
            return 3 // Adjust by beats, by seconds, no adjustments
        } else if comboBox.identifier?.rawValue == "ddlbPlayPositionOffset" {
            return 3 // No offset, beats, seconds
        }

        return 0
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if comboBox.identifier?.rawValue == "ddlbBeatsChangeBehavior" {
            switch index {
                case 0:
                    return NSLocalizedString("beatsChangeBehaviorAdjustFollowing", bundle: Bundle.main, comment: "") as NSString
                case 1:
                    return NSLocalizedString("beatsChangeBehaviorMoveAllFollowing", bundle: Bundle.main, comment: "") as NSString
                default:
                    return NSString(string: "")
            }
        } else if comboBox.identifier?.rawValue == "ddlbAddPositionBehavior" {
            switch index {
                case 0:
                    return NSLocalizedString("addPositionBehaviorNoChange", bundle: Bundle.main, comment: "") as NSString
                case 1:
                    return NSLocalizedString("addPositionBehaviorAdjustBeats", bundle: Bundle.main, comment: "") as NSString
                case 2:
                    return NSLocalizedString("addPositionBehaviorAdjustSeconds", bundle: Bundle.main, comment: "") as NSString
                default:
                    return NSString(string: "")
            }
        } else if comboBox.identifier?.rawValue == "ddlbPlayPositionOffset" {
            switch index {
                case 0:
                    return NSLocalizedString("addPositionBehaviorNoChange", bundle: Bundle.main, comment: "") as NSString
                case 1:
                    return NSLocalizedString("addPositionBehaviorAdjustBeats", bundle: Bundle.main, comment: "") as NSString
                case 2:
                    return NSLocalizedString("addPositionBehaviorAdjustSeconds", bundle: Bundle.main, comment: "") as NSString
                default:
                    return NSString(string: "")
            }
        }

        return NSString(string: "")

    }

    func comboBoxSelectionDidChange(_ notification: Notification) {
        let uiElement: NSControl = notification.object as! NSControl
        if uiElement.identifier?.rawValue == "ddlbBeatsChangeBehavior" {
            UserDefaults.standard.set(self.ddlbBeatsBehaviorChange.indexOfSelectedItem, forKey: UserDefaults.Keys.prefBeatsChangeBehaviour.rawValue)
        } else if uiElement.identifier?.rawValue == "ddlbAddPositionBehavior" {
            UserDefaults.standard.set(self.ddlbAddPositionBehavior.indexOfSelectedItem, forKey: UserDefaults.Keys.prefAddPositionBehaviour.rawValue)
        } else if uiElement.identifier?.rawValue == "ddlbPlayPositionOffset" {
            UserDefaults.standard.set(self.ddlbPlayPositionOffset.indexOfSelectedItem, forKey: UserDefaults.Keys.prefPlayPositionOffset.rawValue)
        }

    }
}
