//
//  AppDelegate.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 12.04.18.
//  MIT License
//

import Cocoa
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        Database.buildTablesIfNeeded()
        
        if UserDefaults.standard.double(forKey: "prefFilterTitleFactor") == 0 {
            UserDefaults.standard.set(1.0, forKey: "prefFilterTitleFactor")
        }
        
        //Sparkle, if the automatic updates are turned on, perform an initial check on app launch
        if let updater = SUUpdater.shared(){
            if updater.automaticallyChecksForUpdates {
                delayWithSeconds(5){
                    updater.checkForUpdatesInBackground()
                    updater.resetUpdateCycle()
                }
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
        // Stop current song
        NotificationCenter.default.post(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        usleep(100000) // 100 ms
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}

