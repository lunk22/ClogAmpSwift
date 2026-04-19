//
//  MainWindow.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 15.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import Foundation

class MainWindow: NSWindowController {
    
    @IBOutlet weak var tbPlay: NSButton!
    @IBOutlet weak var tbPause: NSButton!
    @IBOutlet weak var tbStop: NSButton!
    @IBOutlet weak var segTabs: NSSegmentedControl!
    
    
    override func windowDidLoad() {
        window?.setFrameAutosaveName("mainWindowAutosave")
//        window?.appearance = NSAppearance(named: .aqua)     // Light
//        window?.appearance = NSAppearance(named: .darkAqua) // Dark
//        window?.appearance = nil                            // Inherit
        
        super.windowDidLoad()
        
        let viewController = contentViewController as! MainView;
        viewController.mainWindow = self
        
        self.segTabs.selectedSegment = 0
    }
    
    @IBAction func tbPlay(_ sender: Any) {
        let viewController = contentViewController as! MainView;
        viewController.play(self)
    }
    
    @IBAction func tbPause(_ sender: Any) {
        let viewController = contentViewController as! MainView;
        viewController.pause(self)
    }
    
    @IBAction func tbStop(_ sender: Any) {
        let viewController = contentViewController as! MainView;
        viewController.stop(self)
    }
    
    @IBAction func handleSwitchSegment(_ sender: NSSegmentedControl) {
        let viewController = contentViewController as! MainView;
        
        viewController.tabView.selectTabViewItem(at: sender.selectedSegment)
    }
    @IBAction func handleFocusFilter(_ sender: NSButton) {
        let viewController = contentViewController as! MainView;
        
        viewController.focusFilterField(self)
    }
}
