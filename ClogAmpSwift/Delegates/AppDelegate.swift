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
    
    override init() {
        super.init()
        
        ValueTransformer.setValueTransformer( DecibelTransformer(), forName: .decibelTransformer )
        ValueTransformer.setValueTransformer( HertzTransformer(), forName: .hertzTransformer )
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        if let appDomain = Bundle.main.bundleIdentifier {
//            UserDefaults.standard.removePersistentDomain(forName: appDomain)
//        }
//        NSApplication.shared.terminate(self)
        
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
        
        // Shutdown Audio API
        NotificationCenter.default.post(name: PlayerAudioEngine.NotificationNames.shutdown, object: nil)
        
        // Wait 1 sec
        let ms: UInt32 = 1000
        usleep(1000 * ms) // 1000 ms = 1 sec
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func openUpdateHistory(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://htmlpreview.github.io/?https://github.com/lunk22/ClogAmpSwift/blob/master/ClogAmpSwift/UpdateHistory.html")!)
    }
    
}

