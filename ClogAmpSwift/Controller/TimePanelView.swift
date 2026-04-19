//
//  TimePanelView.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 28.01.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class TimePanelView: ViewController {
    /*
     * Outlets
     */
    @IBOutlet weak var textFieldTime: NSTextField!
    
    
    /*
     * Properties
     */
    var bViewVisible: Bool = false
    
    
    /*
     * Functions
     */
    override func viewWillAppear() {
        self.bViewVisible = true
        self.tick()
    }
    
//    override func viewDidAppear() {
//        self.bViewVisible = true
//        self.tick()
//    }
    
    override func viewDidDisappear() {
        self.bViewVisible = false
    }
    
    func tick(single: Bool = false) {
        //Do Some Stuff while the track is playing to update the UI...
        let date     = Date()
        let calendar = Calendar.current
        let hours    = calendar.component(.hour, from: date)
        let minutes  = calendar.component(.minute, from: date)
        let seconds  = calendar.component(.second, from: date)
        
        var time = ""
        if(hours < 10) {
            time += "0\(hours)"
        }else{
            time += "\(hours)"
        }
        
        if(minutes < 10) {
            time += ":0\(minutes)"
        }else{
            time += ":\(minutes)"
        }
        
        if(seconds < 10) {
            time += ":0\(seconds)"
        }else{
            time += ":\(seconds)"
        }
        
        textFieldTime.stringValue = time
        
        //re-trigger the update while the player is playing
        if self.bViewVisible {
            delayWithSeconds(0.01) {
                self.tick()
            }
        }
    }
    
}
