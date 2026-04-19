//
//  Position.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 24.01.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import Foundation

class Position {
    var name: String {
        didSet {
            self.hasChanges = true
        }
    }
    var comment: String {
        didSet {
            self.hasChanges = true
        }
    }
    var jumpTo:  String {
        didSet {
            self.hasChanges = true
        }
    }
    var time: UInt { // in ms
        didSet {
            self.hasChanges = true
        }
    }
    var beats: Int
    private(set) var hasChanges: Bool
    
    //  Initializer
    init() {
        self.name       = ""
        self.comment    = ""
        self.jumpTo     = ""
        self.time       = 0
        self.beats      = 0 // Calculated
        self.hasChanges = false
    }
    
    convenience init(name: String, comment: String, time: UInt, new: Bool) {
        self.init()
        
        self.name    = name
        self.comment = comment
        self.time    = time
        self.hasChanges = new
    }
    
    convenience init(name: String, comment: String, jumpTo: String, time: UInt, new: Bool) {
        self.init()
        
        self.name    = name
        self.comment = comment
        self.jumpTo  = jumpTo
        self.time    = time
        self.hasChanges = new
    }
    
    func getValueAsString(_ property: String) -> String {
        switch property {
            case "name":
                return self.name
            case "comment":
                return self.comment
            case "jumpTo":
                return self.jumpTo
            case "beats":
                return "\(self.beats)"
            case "time":
                //time = milliseconds
                var calcTime = self.time
                let msec = calcTime % 1000
                calcTime -= msec
                calcTime /= 1000
                let sec  = calcTime % 60
                calcTime -= sec
                let min  = calcTime / 60
                
                var sMsec = "\(msec)"
                if(msec < 10){
                    sMsec = "00"+sMsec
                }else if(msec < 100){
                    sMsec = "0"+sMsec
                }
                
                var sSec = "\(sec)"
                if(sec < 10){
                    sSec = "0"+sSec
                }
                
                return "\(min):"+sSec+":"+sMsec
            default:
                return ""
        }
    } //func getValueAsString
    
    func resetChangeFlag() {
        self.hasChanges = false
    }
}
