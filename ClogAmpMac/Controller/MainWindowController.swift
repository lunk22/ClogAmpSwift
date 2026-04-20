//
//  MainWindowController.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 15.02.19.
//

import Foundation

class MainWindowController: NSWindowController {
    
    @IBOutlet weak var tbPlay: NSButton!
    @IBOutlet weak var tbPause: NSButton!
    @IBOutlet weak var tbStop: NSButton!
    @IBOutlet weak var segTabs: NSSegmentedControl!
    
    override func windowDidLoad() {
        window?.setFrameAutosaveName("mainWindowAutosave")
        
        super.windowDidLoad()
        
        let viewController = contentViewController as! MainViewController;
        viewController.mainWindow = self
        
        self.segTabs.selectedSegment = 0
    }
    
    @IBAction func tbPlay(_ sender: Any) {
        let viewController = contentViewController as! MainViewController;
        viewController.play(self)
    }
    
    @IBAction func tbPause(_ sender: Any) {
        let viewController = contentViewController as! MainViewController;
        viewController.pause(self)
    }
    
    @IBAction func tbStop(_ sender: Any) {
        let viewController = contentViewController as! MainViewController;
        viewController.stop(self)
    }
    
    @IBAction func handleSwitchSegment(_ sender: NSSegmentedControl) {
        let viewController = contentViewController as! MainViewController;
        
        viewController.tabView.selectTabViewItem(at: sender.selectedSegment)
    }
    @IBAction func handleFocusFilter(_ sender: NSButton) {
        let viewController = contentViewController as! MainViewController;
        
        viewController.focusFilterField(self)
    }
}
