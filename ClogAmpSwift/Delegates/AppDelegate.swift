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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        Database.buildTablesIfNeeded()
        
        //Sparkle, if the automatic updates are turned on, perform an initial check on app launch
        if let updater = SUUpdater.shared(){
            if updater.automaticallyChecksForUpdates {
                delayWithSeconds(5) {
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
        NotificationCenter.default.post(name: Notification.Name("CAM_Shutdown"), object: nil)
        
        // Wait 1 sec
        let ms: UInt32 = 1000
        usleep(1000 * ms) // 1000 ms = 1 sec
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}

