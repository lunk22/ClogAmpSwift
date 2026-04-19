//
//  SettingsPositionsViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 27.11.24.
//  Copyright © 2024 Pascal Roessel. All rights reserved.
//

import AppKit

class SettingsPositionsViewController: NSViewController {
    
    // MARK: VARS
    @objc let defaults: UserDefaults = .standard
    
    // MARK: OUTLETS
    @IBOutlet weak var ddlbAddPositionBehavior: NSComboBox!    
    @IBOutlet weak var ddlbBeatsBehaviorChange: NSComboBox!
    @IBOutlet weak var cwHighlightColor: NSColorWell!
    @IBOutlet weak var cwTextColor: NSColorWell!
    
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
    
    // MARK: View overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ddlbAddPositionBehavior.selectItem(at: Settings.addPositionBehavior)
        self.ddlbBeatsBehaviorChange.selectItem(at: Settings.beatsChangeBehavior)
        
        self.cwHighlightColor.color = Settings.positionHighlightColor
        self.cwTextColor.color = Settings.positionTextColor
    }
}

extension SettingsPositionsViewController : NSComboBoxDelegate, NSComboBoxDataSource {
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        if comboBox.identifier?.rawValue == "ddlbBeatsChangeBehavior" {
            return 2 //Adjust next position, move all following positions
        } else if comboBox.identifier?.rawValue == "ddlbAddPositionBehavior" {
            return 3 // Adjust by beats, by seconds, no adjustments
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
        }

        return NSString(string: "")
        
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let uiElement: NSControl = notification.object as! NSControl
        if uiElement.identifier?.rawValue == "ddlbBeatsChangeBehavior" {
            UserDefaults.standard.set(self.ddlbBeatsBehaviorChange.indexOfSelectedItem, forKey: UserDefaults.Keys.prefBeatsChangeBehaviour.rawValue)
        } else if uiElement.identifier?.rawValue == "ddlbAddPositionBehavior" {
            UserDefaults.standard.set(self.ddlbAddPositionBehavior.indexOfSelectedItem, forKey: UserDefaults.Keys.prefAddPositionBehaviour.rawValue)
        }

    }
}
