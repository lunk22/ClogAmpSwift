//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 12.04.18.
//  MIT License
//

import AppKit

class MainView: NSViewController {
    
    var aSongs         = [Song]()
    var aSongsForTable = [Song]()
    
    var sSortBy        = "title"
    var bSortAsc       = true
    
    weak var playerView: PlayerView?
    weak var songTableView: SongTableView?
    weak var positionTableView: PositionTableView?
    
    // Overrides
    //    override func viewDidLoad() {
    //        super.viewDidLoad()
    //
    //        // Do any additional setup after loading the view.
    //    }
    
    override func viewWillDisappear() {
        self.playerView?.getSong()?.saveChanges()
    }
    
    override func keyDown(with event: NSEvent) {
        
//        let keyPressed = (event.characters ?? "").lowercased()
//        print("Key: \(keyPressed) - Code: \(event.keyCode)")
        
        switch event.keyCode {
            case 30: // +
                self.playerView!.increaseSpeed()
            case 44: // -
                self.playerView!.decreaseSpeed()
            case 35: // P
                self.playerView!.play()
            case 1: // S
                self.playerView!.stop()
            case 49: // Space
                self.playerView!.pause()
            case 3: // F
                if(event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.shift]){
                    self.songTableView?.searchField.becomeFirstResponder()
                }else{
                    self.interpretKeyEvents([event])
                }
            default:
                self.interpretKeyEvents([event])
        }

    }
    
    override func viewDidAppear() {
        self.playerView        = self.children[0] as? PlayerView
        self.songTableView     = self.children[1] as? SongTableView
        self.positionTableView = self.children[2] as? PositionTableView
        
        self.songTableView?.mainView = self
        self.positionTableView?.mainView = self
    }
}
