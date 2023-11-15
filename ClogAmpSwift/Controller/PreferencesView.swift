//
//  PreferencesView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 18.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit
import Sparkle

class PreferenceView: ViewController {
    
    //Outlets
    @IBOutlet weak var txtSkipForward: NSTextField!
    @IBOutlet weak var txtSkipBack: NSTextField!
    @IBOutlet weak var txtBpmUpperBound: NSTextField!
    @IBOutlet weak var txtBpmLowerBound: NSTextField!
    @IBOutlet weak var txtLoopDelay: NSTextField!
    @IBOutlet weak var boxAppearance: NSBox!
    @IBOutlet weak var ddlbAppearance: NSComboBox!
    @IBOutlet weak var cbViewAfterSongLoad: NSComboBox!
    
    //Overrides
    override func viewDidLoad() {
        
        //Read Defaults / create them accordingly
        var prefSkipForwardSeconds = UserDefaults.standard.integer(forKey: "prefSkipForwardSeconds")
        if prefSkipForwardSeconds == 0 {
            prefSkipForwardSeconds = 5
        }
        
        var prefSkipBackSeconds = UserDefaults.standard.integer(forKey: "prefSkipBackSeconds")
        if prefSkipBackSeconds == 0 {
            prefSkipBackSeconds = 5
        }
                
        var prefBpmUpperBound = UserDefaults.standard.integer(forKey: "prefBpmUpperBound")
        if prefBpmUpperBound == 0 {
            prefBpmUpperBound = 140
        }
        
        var prefBpmLowerBound = UserDefaults.standard.integer(forKey: "prefBpmLowerBound")
        if prefBpmLowerBound == 0 {
            prefBpmLowerBound = 70
        }
        
        let prefLoopDelay        = UserDefaults.standard.double(forKey: "prefLoopDelay")
                
        var prefAppearance = UserDefaults.standard.integer(forKey: "prefAppearance")
        var prefViewAfterSongLoad = UserDefaults.standard.integer(forKey: "prefViewAfterSongLoad")
        
        self.txtSkipForward.integerValue   = prefSkipForwardSeconds
        self.txtSkipBack.integerValue      = prefSkipBackSeconds
        self.txtBpmUpperBound.integerValue = prefBpmUpperBound
        self.txtBpmLowerBound.integerValue = prefBpmLowerBound
        self.txtLoopDelay.doubleValue      = prefLoopDelay
        
        if(prefAppearance < 0 || prefAppearance > 2){
           prefAppearance = 0
        }
        self.ddlbAppearance.selectItem(at: prefAppearance)
        
        if(prefViewAfterSongLoad < 0 || prefViewAfterSongLoad > 2){
            prefViewAfterSongLoad = 0
        }
        self.cbViewAfterSongLoad.selectItem(at: prefViewAfterSongLoad)
        
        if #available(OSX 10.14, *) {
            self.boxAppearance.isHidden = false
        }else{
            self.boxAppearance.isHidden = true
        }
        
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
        if sender === self.txtSkipForward! {
            UserDefaults.standard.set(self.txtSkipForward.integerValue, forKey: "prefSkipForwardSeconds")
        }else if sender === self.txtSkipBack! {
            UserDefaults.standard.set(self.txtSkipBack.integerValue, forKey: "prefSkipBackSeconds")
        }else if sender === self.txtBpmUpperBound! {
            UserDefaults.standard.set(self.txtBpmUpperBound.integerValue, forKey: "prefBpmUpperBound")
        }else if sender === self.txtBpmLowerBound! {
            UserDefaults.standard.set(self.txtBpmLowerBound.integerValue, forKey: "prefBpmLowerBound")
        }else if sender === self.txtLoopDelay! {
            UserDefaults.standard.set(self.txtLoopDelay.doubleValue, forKey: "prefLoopDelay")
        }
    }
    
    @IBAction func handleAutomaticUpdatesChange(_ sender: NSButton) {
        if sender.state == NSControl.StateValue.on {
            //Sparkle, if the automatic updates are turned on, perform an initial check on app launch
            if let updater = SUUpdater.shared(){
                if updater.automaticallyChecksForUpdates {
                    delayWithSeconds(1){
                        updater.checkForUpdatesInBackground()
                        updater.resetUpdateCycle()
                    }
                }
            }
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
        return 3 //Dark, Light, System
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
            UserDefaults.standard.set(self.ddlbAppearance.indexOfSelectedItem, forKey: "prefAppearance")
        } else if uiElement.identifier?.rawValue == "cbViewAfterSongLoad" {
            UserDefaults.standard.set(self.cbViewAfterSongLoad.indexOfSelectedItem, forKey: "prefViewAfterSongLoad")
        }
        
    }
}
