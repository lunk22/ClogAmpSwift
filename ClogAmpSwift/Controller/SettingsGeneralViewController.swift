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
    
    // MARK: OUTLETS
    @IBOutlet weak var ddlbAppearance: NSComboBox!
    @IBOutlet weak var ddlbViewAfterSongLoad: NSComboBox!
    
    // MARK: ACTIONS
    @IBAction func handleMonoChanged(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("monoChanged"), object: nil)
    }
    
    @IBAction func handleSleepPreventionChanged(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("preventSystemSleepChanged"), object: nil)
    }
    
    // MARK: View overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ddlbAppearance.selectItem(at: Settings.appearance)
        self.ddlbViewAfterSongLoad.selectItem(at: Settings.viewAfterSongLoad)
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
