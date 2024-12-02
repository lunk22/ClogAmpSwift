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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
//    public let updateController: SPUStandardUpdaterController
    
    override init() {
//        updateController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        // Access via:
        // NSApplication.shared.delegate as! AppDelegate
        
        ValueTransformer.setValueTransformer( DecibelTransformer(), forName: .decibelTransformer )
        ValueTransformer.setValueTransformer( HertzTransformer(), forName: .hertzTransformer )
        
        super.init()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {        
//        UserDefaults.standard.reset() // Extension method - ONLY FOR TESTING
        
        Database.buildTablesIfNeeded()
        
//        showMenuBarItem()  // just to play around a little
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Shutdown Audio API
        NotificationCenter.default.post(name: PlayerAudioEngine.NotificationNames.shutdown, object: nil)
        
        // Wait 1 sec
        let ms: UInt32 = 1000
        usleep(1000 * ms) // 1000 ms = 1 sec
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
            menuItem.title = "I don't to anything"
            
            statusBarMenu.addItem(menuItem)
            
            self.statusBarItem = statusBarItem
        }
    }
    
    @IBAction func openUpdateHistory(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://htmlpreview.github.io/?https://github.com/lunk22/ClogAmpSwift/blob/master/ClogAmpSwift/UpdateHistory.html")!)
    }
    
}

