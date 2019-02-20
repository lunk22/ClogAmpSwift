//
//  PreferencesView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 18.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class PreferenceView: ViewController {
    
    //Outlets
    @IBOutlet weak var txtSkipForward: NSTextField!
    @IBOutlet weak var txtSkipBack: NSTextField!
    @IBOutlet weak var cbPlayPosOnSelection: NSButton!
    @IBOutlet weak var txtBpmUpperBound: NSTextField!
    @IBOutlet weak var txtBpmLowerBound: NSTextField!
    
    //Overrides
    override func viewDidLoad() {
        
        //Read Defaults / create them accordingly
        var prefSkipForwardSeconds = UserDefaults.standard.integer(forKey: "prefSkipForwardSeconds")
        if prefSkipForwardSeconds == 0 {
            prefSkipForwardSeconds = 5
//            UserDefaults.standard.set(5, forKey: "prefSkipForwardSeconds")
        }
        
        var prefSkipBackSeconds = UserDefaults.standard.integer(forKey: "prefSkipBackSeconds")
        if prefSkipBackSeconds == 0 {
            prefSkipBackSeconds = 5
//            UserDefaults.standard.set(5, forKey: "prefSkipBackSeconds")
        }
        
        let prefPlayPositionOnSelection = UserDefaults.standard.bool(forKey: "prefPlayPositionOnSelection")
        
        var prefBpmUpperBound = UserDefaults.standard.integer(forKey: "prefBpmUpperBound")
        if prefBpmUpperBound == 0 {
            prefBpmUpperBound = 140
//            UserDefaults.standard.set(140, forKey: "prefBpmUpperBound")
        }
        
        var prefBpmLowerBound = UserDefaults.standard.integer(forKey: "prefBpmLowerBound")
        if prefBpmLowerBound == 0 {
            prefBpmLowerBound = 70
//            UserDefaults.standard.set(70, forKey: "prefBpmLowerBound")
        }
        
        txtSkipForward.stringValue = "\(prefSkipForwardSeconds)"
        txtSkipBack.stringValue = "\(prefSkipBackSeconds)"
        
        if(prefPlayPositionOnSelection == true){
            cbPlayPosOnSelection.state = NSControl.StateValue.on
        }else{
            cbPlayPosOnSelection.state = NSControl.StateValue.off
        }
        
        txtBpmUpperBound.stringValue = "\(prefBpmUpperBound)"
        txtBpmLowerBound.stringValue = "\(prefBpmLowerBound)"
        
        super.viewDidLoad()
    }
    
    @IBAction func setValue(_ sender: AnyObject) {
        if sender === self.txtSkipForward! {
            UserDefaults.standard.set(sender.stringValue ?? 5, forKey: "prefSkipForwardSeconds")
        }else if sender === self.txtSkipBack! {
            UserDefaults.standard.set(sender.stringValue ?? 5, forKey: "prefSkipBackSeconds")
        }else if sender === self.cbPlayPosOnSelection! {
            let state = (sender.state ?? NSControl.StateValue.off) == NSControl.StateValue.on
            UserDefaults.standard.set(state, forKey: "prefPlayPositionOnSelection")
        }else if sender === self.txtBpmUpperBound! {
            UserDefaults.standard.set(sender.stringValue ?? 140, forKey: "prefBpmUpperBound")
        }else if sender === self.txtBpmLowerBound! {
            UserDefaults.standard.set(sender.stringValue ?? 70, forKey: "prefBpmLowerBound")
        }
    }
    @IBAction func setAppIcon(_ sender: NSButton) {
        if let iconName = sender.identifier?.rawValue {
            UserDefaults.standard.set(iconName, forKey: "AppIconName")
            NSApplication.shared.applicationIconImage = NSImage(named: iconName)
        }
    }
}
