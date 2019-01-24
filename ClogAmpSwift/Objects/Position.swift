//
//  Position.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 24.01.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import Foundation

class Position {
    var name: String
    var comment: String
    var jumpTo:  String
    var time: UInt
    
    //  Initializer
    init() {
        self.name    = ""
        self.comment = ""
        self.jumpTo  = ""
        self.time    = 0
    }
    
    convenience init(name: String, comment: String, time: UInt) {
        self.init()
        
        self.name    = name
        self.comment = comment
        self.time    = time
    }
    
    convenience init(name: String, comment: String, jumpTo: String, time: UInt) {
        self.init()
        
        self.name    = name
        self.comment = comment
        self.jumpTo  = jumpTo
        self.time    = time
    }
    
    func getValueAsString(_ property: String) -> String {
        switch property {
            case "name":
                return self.name
            case "comment":
                return self.comment
            case "jumpTo":
                return self.jumpTo
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
}
