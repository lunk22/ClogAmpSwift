//
//  MainViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 12.04.18.
//

import AppKit

class MainViewController: ViewController {
    
    weak var mainWindow: MainWindowController?
    
    weak var playerView: PlayerViewController?
    weak var songTableView: SongTableViewController?
    weak var positionTableView: PositionTableViewController?
    weak var pdfView: PDFViewController?
    
    @IBOutlet weak var tabView: NSTabView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillDisappear() {
        PlayerAudioEngine.shared.song?.saveChanges()
        super.viewWillDisappear()
    }
    
    override func viewDidAppear() {
        self.songTableView     = self.children[0] as? SongTableViewController
        self.positionTableView = self.children[1] as? PositionTableViewController
        self.pdfView           = self.children[2] as? PDFViewController
        self.playerView        = self.children[3] as? PlayerViewController

        self.pdfView?.mainView           = self
        self.playerView?.mainView        = self
        self.songTableView?.mainView     = self
        self.positionTableView?.mainView = self

        super.viewDidAppear()
    }
    
    override func viewDidDisappear() {

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

extension MainViewController: NSTabViewDelegate {
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
