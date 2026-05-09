//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 29.01.19.
//

import AppKit

class ViewController : NSViewController {
    
    override func keyDown(with event: NSEvent) {
        if KeyboardShortcutManager.shared.shortcut(for: .playPause)?.matches(event) == true {
            PlayerAudioEngine.shared.pause() // Menu doesn't react to space bar as key equivalent
        } else {
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
        PlayerAudioEngine.shared.jump(Settings.skipForward)
    }
    
    @IBAction func playerBack(_ sender: AnyObject) {
        PlayerAudioEngine.shared.jump(Settings.skipBack * -1)
    }
    
    @IBAction func saveSong(_ sender: Any) {
        PlayerAudioEngine.shared.song?.saveChanges()
    }
}
