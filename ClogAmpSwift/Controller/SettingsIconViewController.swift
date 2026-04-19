//
//  SettingsIconViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 28.11.24.
//  Copyright © 2024 Pascal Roessel. All rights reserved.
//

import AppKit

class SettingsIconViewController: NSViewController {
    
    // MARK: OUTLETS
    @IBOutlet weak var rbAppIcon: NSButton!
    @IBOutlet weak var rbAppIconBlue: NSButton!
    @IBOutlet weak var rbAppIconRed: NSButton!
    @IBOutlet weak var rbAppIconDarkRed: NSButton!
    @IBOutlet weak var rbAppIconTeal: NSButton!
    @IBOutlet weak var rbAppIconGray: NSButton!
    @IBOutlet weak var rbAppIconOrange: NSButton!
    @IBOutlet weak var rbAppIconWhite: NSButton!
    
    // MARK: INIT
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateRadioButtons()
    }
    
    // MARK: ACTIONS
    @IBAction func setAppIcon(_ sender: NSButton) {
        if let iconName = sender.identifier?.rawValue {
            guard let newIcon = NSImage(named: NSImage.Name(iconName)) else { return }
            
            UserDefaults.standard.set(iconName, forKey: "AppIconName")
            
            // Currently running instance
            NSApplication.shared.applicationIconImage = newIcon
            // App in general
            NSWorkspace.shared.setIcon(newIcon, forFile: Bundle.main.bundleURL.path)
            
            // Update UI
            updateRadioButtons()
        }
    }
    
    private func updateRadioButtons() {
        rbAppIcon.state = Settings.appIconName == nil || Settings.appIconName == "AppIcon" ? .on : .off
        rbAppIconBlue.state = Settings.appIconName == "AppIconBlue" ? .on : .off
        rbAppIconRed.state = Settings.appIconName == "AppIconRed" ? .on : .off
        rbAppIconDarkRed.state = Settings.appIconName == "AppIconDarkRed" ? .on : .off
        rbAppIconTeal.state = Settings.appIconName == "AppIconTeal" ? .on : .off
        rbAppIconGray.state = Settings.appIconName == "AppIconGray" ? .on : .off
        rbAppIconOrange.state = Settings.appIconName == "AppIconOrange" ? .on : .off
        rbAppIconWhite.state = Settings.appIconName == "AppIconWhite" ? .on : .off
    }
}
