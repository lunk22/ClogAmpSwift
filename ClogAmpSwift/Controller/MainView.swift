//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 12.04.18.
//  MIT License
//

import AppKit

class MainView: ViewController {
    
    weak var mainWindow: MainWindow?
    
    weak var playerView: PlayerView?
    weak var songTableView: SongTableView?
    weak var positionTableView: PositionTableView?
    weak var pdfView: PDFViewController?
    
    @IBOutlet weak var tabView: NSTabView!
        
    override func viewWillAppear() {
        
        if let iconName = AppPreferences.appIconName {
            NSApplication.shared.applicationIconImage = NSImage(contentsOfFile: Bundle.main.path(forResource: iconName, ofType: "icns") ?? "")
        }
        
    }
    
    override func viewWillDisappear() {
        PlayerAudioEngine.shared.song?.saveChanges()
        super.viewWillDisappear()
    }
    
    override func viewDidAppear() {
        self.songTableView     = self.children[0] as? SongTableView
        self.positionTableView = self.children[1] as? PositionTableView
        self.pdfView           = self.children[2] as? PDFViewController
        self.playerView        = self.children[3] as? PlayerView

        self.pdfView?.mainView           = self
        self.playerView?.mainView        = self
        self.songTableView?.mainView     = self
        self.positionTableView?.mainView = self
        
        super.viewDidAppear()
    }
    
    @IBAction func increaseSpeed(_ sender: AnyObject) {
        self.playerView?.increaseSpeed(1)
    }
    
    @IBAction func decreaseSpeed(_ sender: AnyObject) {
        self.playerView?.decreaseSpeed(1)
    }

    @IBAction func increaseSpeed5(_ sender: AnyObject) {
        self.playerView?.increaseSpeed(5)
    }

    @IBAction func decreaseSpeed5(_ sender: AnyObject) {
        self.playerView?.decreaseSpeed(5)
    }

    @IBAction func resetPlayerSpeed(_ sender: AnyObject) {
        self.playerView?.resetSpeed()
    }
    
    @IBAction func focusFilterField(_ sender: Any) {
        self.tabView.selectTabViewItem(at: 0)
        self.songTableView?.searchField.becomeFirstResponder()
    }
    
    @IBAction func determineBpm(_ sender: Any) {
        self.playerView?.determineBpmFCS()
    }  
}

extension MainView: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        self.positionTableView?.visible = false
        
        if(tabViewItem?.identifier as? String == "songs"){
            if(tabViewItem?.tabState == NSTabViewItem.State.selectedTab){
                self.mainWindow?.segTabs.selectedSegment = 0
            }
        }else if(tabViewItem?.identifier as? String == "positions"){
            if(tabViewItem?.tabState == NSTabViewItem.State.selectedTab){
                self.positionTableView?.visible = true
                self.mainWindow?.segTabs.selectedSegment = 1
            }
        }else if(tabViewItem?.identifier as? String == "pdf"){
            if(tabViewItem?.tabState == NSTabViewItem.State.selectedTab){
                self.mainWindow?.segTabs.selectedSegment = 2
            }
        }
    }
}
