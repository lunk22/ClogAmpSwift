//
//  Song.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 13.04.18.
//  Copyright © 2018 Pascal Roessel. All rights reserved.
//

import Foundation

class Song {
    
    //  Properties
    var path: URL
    var title: String
    var artist: String
    var level: String
    var duration: String
    var speed: String
    var bpm: UInt
    
    
    //  Initializer
    init(path: URL) {
        self.path = path
        self.title = path.deletingPathExtension().lastPathComponent
        self.artist = ""
        self.level = ""
        self.duration = ""
        self.speed = ""
        self.bpm = 0
    }
    
    func getValueAsString(_ property: String) -> String {
        switch property {
        case "path":
            var path = self.path.absoluteString
            path = path.removingPercentEncoding!
            return path
        case "title":
            return self.title
        case "artist":
            return self.artist
        case "level":
            return self.level
        case "duration":
            return self.duration
        case "speed":
            return self.speed
        case "bpm":
            return "\(self.bpm)"
        default:
            return ""
        }
    }
}
