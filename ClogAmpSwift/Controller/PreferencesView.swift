//
//  PreferencesView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 18.02.19.
//

import AppKit
import Sparkle

class PreferenceView: ViewController, NSTextFieldDelegate {
    
    //Outlets
    @IBOutlet weak var txtSkipForward: NSTextField!
    @IBOutlet weak var txtSkipBack: NSTextField!
    @IBOutlet weak var txtBpmUpperBound: NSTextField!
    @IBOutlet weak var txtBpmLowerBound: NSTextField!
    @IBOutlet weak var txtLoopDelay: NSTextField!
    @IBOutlet weak var boxAppearance: NSBox!
    @IBOutlet weak var ddlbAppearance: NSComboBox!
    @IBOutlet weak var cbViewAfterSongLoad: NSComboBox!
    @IBOutlet weak var cbBeatsChangeBehavior: NSComboBox!
    @IBOutlet weak var cbAddPositionBehavior: NSComboBox!
    @IBOutlet weak var txtAddPositionOffset: NSTextField!
    @IBOutlet weak var cwHighlightColor: NSColorWell!
    @IBOutlet weak var cwTextColor: NSColorWell!
    @IBOutlet weak var cbChangeMatchingPositions: NSButton!
    
    //Overrides
    override func viewDidLoad() {
        self.txtSkipForward.integerValue   = Settings.skipForward
        self.txtSkipBack.integerValue      = Settings.skipBack
        self.txtBpmUpperBound.integerValue = Settings.bpmUpperBound
        self.txtBpmLowerBound.integerValue = Settings.bpmLowerBound
        self.txtLoopDelay.doubleValue      = Settings.loopDelay
        self.txtAddPositionOffset.integerValue = Settings.addPositionOffset

        self.ddlbAppearance.selectItem(at: Settings.appearance)
        self.cbViewAfterSongLoad.selectItem(at: Settings.viewAfterSongLoad)
        self.cbBeatsChangeBehavior.selectItem(at: Settings.beatsChangeBehavior)
        self.cbAddPositionBehavior.selectItem(at: Settings.addPositionBehavior)
        
        self.cwHighlightColor.color = Settings.positionHighlightColor
        self.cwTextColor.color = Settings.positionTextColor
        
        super.viewDidLoad()
    }
    
    //MARK: Actions
    @IBAction func handleMonoChanged(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("monoChanged"), object: nil)
    }
    
    @IBAction func handleShowBeatsChanged(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("showBeats"), object: nil)
    }
    
    @IBAction func setValue(_ sender: AnyObject) {
        if sender.identifier == "a" {
            UserDefaults.standard.set(self.txtSkipForward.integerValue, forKey: "prefSkipForwardSeconds")
        }else if sender === self.txtSkipBack! {
            UserDefaults.standard.set(self.txtSkipBack.integerValue, forKey: "prefSkipBackSeconds")
        }else if sender === self.txtBpmUpperBound! {
            UserDefaults.standard.set(self.txtBpmUpperBound.integerValue, forKey: "prefBpmUpperBound")
        }else if sender === self.txtBpmLowerBound! {
            UserDefaults.standard.set(self.txtBpmLowerBound.integerValue, forKey: "prefBpmLowerBound")
        }else if sender === self.txtLoopDelay! {
            UserDefaults.standard.set(self.txtLoopDelay.doubleValue, forKey: "prefLoopDelay")
        }else if sender === self.txtAddPositionOffset! {
            UserDefaults.standard.set(self.txtAddPositionOffset.integerValue, forKey: "prefAddPositionOffset")
        }
    }
    
    @IBAction func handleAutomaticUpdatesChange(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            //Sparkle, if the automatic updates are turned on, perform an initial check on app launch
            if let updater = SUUpdater.shared(){
                if updater.automaticallyChecksForUpdates {
                    delayWithSeconds(1) {
                        updater.checkForUpdatesInBackground()
                        updater.resetUpdateCycle()
                    }
                }
            }
        }
    }
    
    @IBAction func handleColorSelected(_ sender: Any) {
        switch sender as! NSColorWell {
            case self.cwHighlightColor:
                if let data = try? NSKeyedArchiver.archivedData(withRootObject: self.cwHighlightColor.color, requiringSecureCoding: false) {
                    UserDefaults.standard.set(data, forKey: "prefPositionHighlightColor")
                }
            case self.cwTextColor:
                if let data = try? NSKeyedArchiver.archivedData(withRootObject: self.cwTextColor.color, requiringSecureCoding: false) {
                    UserDefaults.standard.set(data, forKey: "prefPositionTextColor")
                }
            default:
                return
        }
    }
    
    
    @IBAction func setAppIcon(_ sender: NSButton) {
        if let iconName = sender.identifier?.rawValue {
            UserDefaults.standard.set(iconName, forKey: "AppIconName")
            NSApplication.shared.applicationIconImage = NSImage(contentsOfFile: Bundle.main.path(forResource: iconName, ofType: "icns") ?? "")
        }
    }
}

//MARK: ComboBox Appearance
extension PreferenceView : NSComboBoxDelegate, NSComboBoxDataSource {
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        if comboBox.identifier?.rawValue == "cbApperance" {
            return 3 //Dark, Light, System
        } else if comboBox.identifier?.rawValue == "cbViewAfterSongLoad" {
            return 3 //Empty, Positions, PDF
        } else if comboBox.identifier?.rawValue == "cbBeatsChangeBehavior" {
            return 2 //Adjust next position, move all following positions
        } else if comboBox.identifier?.rawValue == "cbPositionAddBehavior" {
            return 3 // Adjust by beats, by seconds, no adjustments
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
        } else if comboBox.identifier?.rawValue == "cbBeatsChangeBehavior" {
            switch index {
                case 0:
                    return NSLocalizedString("beatsChangeBehaviorAdjustFollowing", bundle: Bundle.main, comment: "") as NSString
                case 1:
                    return NSLocalizedString("beatsChangeBehaviorMoveAllFollowing", bundle: Bundle.main, comment: "") as NSString
                default:
                    return NSString(string: "")
            }
        } else if comboBox.identifier?.rawValue == "cbPositionAddBehavior" {
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
        if uiElement.identifier?.rawValue == "cbApperance" {
            UserDefaults.standard.set(self.ddlbAppearance.indexOfSelectedItem, forKey: UserDefaults.Keys.prefAppearance.rawValue)
        } else if uiElement.identifier?.rawValue == "cbViewAfterSongLoad" {
            UserDefaults.standard.set(self.cbViewAfterSongLoad.indexOfSelectedItem, forKey: UserDefaults.Keys.prefViewAfterSongLoad.rawValue)
        } else if uiElement.identifier?.rawValue == "cbBeatsChangeBehavior" {
            UserDefaults.standard.set(self.cbBeatsChangeBehavior.indexOfSelectedItem, forKey: UserDefaults.Keys.prefBeatsChangeBehaviour.rawValue)
        } else if uiElement.identifier?.rawValue == "cbPositionAddBehavior" {
            UserDefaults.standard.set(self.cbAddPositionBehavior.indexOfSelectedItem, forKey: UserDefaults.Keys.prefAddPositionBehaviour.rawValue)
        }

    }
}
