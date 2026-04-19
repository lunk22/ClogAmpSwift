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
                self._playerView!.jump(Defaults.skipForward)
            case 11: // B
                self._playerView!.jump((Defaults.skipBack * -1))
            default:
                self.interpretKeyEvents([event])
        }
    }    
}
