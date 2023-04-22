//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 29.01.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class ViewController : NSViewController {
    
    private weak var _playerView: PlayerView?
    
    override func viewDidAppear() {
        let viewController = NSApplication.shared.windows[0].contentViewController as! MainView
        self._playerView = viewController.playerView

        super.viewDidAppear()
    }
    
    override func keyDown(with event: NSEvent) {
            
        switch event.keyCode {
            case 30: // +
                self._playerView!.increaseSpeed()
            case 44: // -
                self._playerView!.decreaseSpeed()
            case 45: // N
                self._playerView!.resetSpeed()
            case 35: // P
                self._playerView!.doPlay()
            case 1: // S
                self._playerView!.doStop()
            case 49: // Space
                self._playerView!.doPause()
            case 3: // F
                var prefSkipForwardSeconds = UserDefaults.standard.integer(forKey: "prefSkipForwardSeconds")
                if prefSkipForwardSeconds == 0 {
                    prefSkipForwardSeconds = 5
                }
                self._playerView!.jump(prefSkipForwardSeconds)
            case 11: // B
                var prefSkipBackSeconds = UserDefaults.standard.integer(forKey: "prefSkipBackSeconds")
                if prefSkipBackSeconds == 0 {
                    prefSkipBackSeconds = 5
                }
                self._playerView!.jump((prefSkipBackSeconds * -1))
            default:
                self.interpretKeyEvents([event])
        }

    }    
}
