//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 29.01.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class ViewController : NSViewController {
    
//    private weak var _playerView: PlayerView?
    
    override func viewDidAppear() {
//        let viewController = NSApplication.shared.windows[0].contentViewController as! MainView
//        self._playerView = viewController.playerView

        super.viewDidAppear()
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
//            case 30: // +
//                self._playerView?.increaseSpeed()
//            case 44: // -
//                self._playerView?.decreaseSpeed()
//            case 45: // N
//                self._playerView?.resetSpeed()
//            case 35: // P
//                PlayerAudioEngine.shared.play()
//            case 1: // S
//                PlayerAudioEngine.shared.stop()
            case 49: // Space
                PlayerAudioEngine.shared.pause()
//            case 3: // F
//                PlayerAudioEngine.shared.jump(Defaults.skipForward)
//            case 11: // B
//                PlayerAudioEngine.shared.jump((Defaults.skipBack * -1))
            default:
                super.keyDown(with: event)
        }
    }
    
    @IBAction func play(_ sender: AnyObject) {
        PlayerAudioEngine.shared.play()
    }
    
    @IBAction func pause(_ sender: AnyObject) {
        PlayerAudioEngine.shared.pause()
    }
    
    @IBAction func stop(_ sender: AnyObject) {
        PlayerAudioEngine.shared.stop()
    }
    
    @IBAction func playerForward(_ sender: AnyObject) {
        PlayerAudioEngine.shared.jump(Defaults.skipForward)
    }
    
    @IBAction func playerBack(_ sender: AnyObject) {
        PlayerAudioEngine.shared.jump(Defaults.skipBack * -1)
    }
    
    @IBAction func saveSong(_ sender: Any) {
        PlayerAudioEngine.shared.song?.saveChanges()
    }
}
