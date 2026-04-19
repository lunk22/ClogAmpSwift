//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 12.04.18.
//  MIT License
//

import AppKit

class MainView: NSViewController {
    
    weak var playerView: PlayerView?
    weak var songTableView: SongTableView?
    weak var positionTableView: PositionTableView?
    weak var pdfView: PDFViewController?
    
    @IBOutlet weak var tabView: NSTabView!
        
    override func viewWillAppear() {
        
        if let iconName = UserDefaults.standard.string(forKey: "AppIconName") {
            NSApplication.shared.applicationIconImage = NSImage(contentsOfFile: Bundle.main.path(forResource: iconName, ofType: "icns") ?? "")
        }
        
    }
    
    override func viewWillDisappear() {
        self.playerView?.getSong()?.saveChanges()
        NSApplication.shared.terminate(self)
    }
    
    override func keyDown(with event: NSEvent) {
        
//        let keyPressed = (event.characters ?? "").lowercased()
//        print("Key: \(keyPressed) - Code: \(event.keyCode)")
        
        switch event.keyCode {
            case 30: // +
                self.playerView!.increaseSpeed()
            case 44: // -
                self.playerView!.decreaseSpeed()
            case 45: // N
                self.playerView!.resetSpeed()
            case 35: // P
                self.playerView!.play()
            case 1: // S
                self.playerView!.stop()
            case 49: // Space
                self.playerView!.pause()
            case 3: // F
                var prefSkipForwardSeconds = UserDefaults.standard.integer(forKey: "prefSkipForwardSeconds")
                if prefSkipForwardSeconds == 0 {
                    prefSkipForwardSeconds = 5
                }
                self.playerView!.jump(prefSkipForwardSeconds)
            case 11: // B
                var prefSkipBackSeconds = UserDefaults.standard.integer(forKey: "prefSkipBackSeconds")
                if prefSkipBackSeconds == 0 {
                    prefSkipBackSeconds = 5
                }
                self.playerView!.jump((prefSkipBackSeconds * -1))
            default:
                self.interpretKeyEvents([event])
        }

    }
    
    override func viewDidAppear() {
        self.songTableView     = self.children[0] as? SongTableView
        self.positionTableView = self.children[1] as? PositionTableView
        self.pdfView           = self.children[2] as? PDFViewController
        self.playerView        = self.children[3] as? PlayerView

        self.playerView?.mainView        = self
        self.songTableView?.mainView     = self
        self.positionTableView?.mainView = self
        
        super.viewDidAppear()
    }
    
    @IBAction func play(_ sender: AnyObject) {
        self.playerView?.play()
    }
    
    @IBAction func pause(_ sender: AnyObject) {
        self.playerView?.pause()
    }
    
    @IBAction func stop(_ sender: AnyObject) {
        self.playerView?.stop()
    }
    
    @IBAction func increaseSpeed(_ sender: AnyObject) {
        self.playerView?.increaseSpeed()
    }
    
    @IBAction func decreaseSpeed(_ sender: AnyObject) {
        self.playerView?.decreaseSpeed()
    }
    
    @IBAction func resetPlayerSpeed(_ sender: AnyObject) {
        self.playerView?.resetSpeed()
    }
    
    @IBAction func playerForward(_ sender: AnyObject) {
        self.playerView?.jump(5)
    }
    
    @IBAction func playerBack(_ sender: AnyObject) {
        self.playerView?.jump(5)
    }
    
    @IBAction func focusFilterField(_ sender: Any) {
        self.tabView.selectTabViewItem(at: 0)
        self.songTableView?.searchField.becomeFirstResponder()
    }
    @IBAction func determineBpm(_ sender: Any){
        self.playerView?.determineBpmFCS()
    }
    
    /*
     --- Store ---
     
     UserDefaults.standard.set(true, forKey: "Key") //Bool
     UserDefaults.standard.set(1, forKey: "Key")  //Integer
     UserDefaults.standard.set("TEST", forKey: "Key") //setObject
     
     --- Retrieve ---
     
     UserDefaults.standard.bool(forKey: "Key")
     UserDefaults.standard.integer(forKey: "Key")
     UserDefaults.standard.string(forKey: "Key")
     
     --- Remove ---
     
     UserDefaults.standard.removeObject(forKey: "Key")
     
     --- Remove all Keys ---
     
     if let appDomain = Bundle.main.bundleIdentifier {
        UserDefaults.standard.removePersistentDomain(forName: appDomain)
     }
     
    */
    
}

extension MainView: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        self.positionTableView?.visible = false
        
        if(tabViewItem?.identifier as? String == "positions"){
            if(tabViewItem?.tabState == NSTabViewItem.State.selectedTab){
                self.positionTableView?.visible = true
            }
        }
    }
}
