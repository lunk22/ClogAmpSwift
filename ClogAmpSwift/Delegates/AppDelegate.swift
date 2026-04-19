//
//  AppDelegate.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 12.04.18.
//  MIT License
//

import Cocoa
import Sparkle
import MediaPlayer
import IOKit
import IOKit.pwr_mgt

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var systemSleepDisabled: Bool = false
    var noSleepAssertionID: IOPMAssertionID = 0

    
    override init() {
        super.init()
        // Access via:
        // NSApplication.shared.delegate as! AppDelegate
        
        ValueTransformer.setValueTransformer( DecibelTransformer(), forName: .decibelTransformer )
        ValueTransformer.setValueTransformer( HertzTransformer(), forName: .hertzTransformer )
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: NSApplication.willResignActiveNotification, object: nil)

        NotificationCenter.default.addObserver(forName: NSNotification.Name("preventSystemSleepChanged"), object: nil, queue: nil){ _ in
            if self.systemSleepDisabled {
                self.reenableSystemSleep()
            } else {
                self.disableSystemSleep()
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        UserDefaults.standard.reset() // Extension method - ONLY FOR TESTING
        
        Database.buildTablesIfNeeded()
        
//        showMenuBarItem()  // just to play around a little
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        NotificationCenter.default.post(name: PlayerAudioEngine.NotificationNames.shutdown, object: nil) // Shutdown Audio API

        reenableSystemSleep()

        return .terminateNow
        
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func showMenuBarItem() {
        // Add a status bar item in the menu bar for our app
        do {
            let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusBarItem.button?.image = NSImage(shape: .play, color: .blue)
            
            let statusBarMenu = NSMenu()
            statusBarItem.menu = statusBarMenu
            
            let menuItem = NSMenuItem()
            menuItem.title = "I don't do anything"
            
            statusBarMenu.addItem(menuItem)
            
            self.statusBarItem = statusBarItem
        }
    }

    func disableSystemSleep() {
        guard !systemSleepDisabled else { return }
        guard Settings.preventSystemSleep else { return }
        
        let noSleepReturn = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "ClogAmpMac active" as CFString,
            &noSleepAssertionID
        )
        guard noSleepReturn == kIOReturnSuccess else { return }
        systemSleepDisabled = true
        print("System Sleep disabled")
    }
    
    func reenableSystemSleep() {
        guard systemSleepDisabled else { return }
        
        let noSleepReturn = IOPMAssertionRelease(noSleepAssertionID)
        guard noSleepReturn == kIOReturnSuccess else { return }
        systemSleepDisabled = false
        print("System Sleep reenabled")
    }
    
    // MARK: Eventhandler / Menu Actions
    @objc func appMovedToForeground() {
        disableSystemSleep()
    }
    
    @objc func appMovedToBackground() {
        reenableSystemSleep()
    }
    
    @IBAction func openUpdateHistory(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://htmlpreview.github.io/?https://github.com/lunk22/ClogAmpSwift/blob/master/ClogAmpSwift/UpdateHistory.html")!)
    }
    
}

