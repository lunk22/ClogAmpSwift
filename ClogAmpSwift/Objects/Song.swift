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
    var speed: Int
    var bpm: UInt
    var volume: UInt
    var hasPositions: Bool
    var positions: Array<Position>
    
    //  Initializer
    init(path: URL) {
        //Initial Values
        self.path         = path
        self.title        = path.deletingPathExtension().lastPathComponent
        self.artist       = ""
        self.level        = ""
        self.duration     = ""
        self.speed        = 0
        self.bpm          = 0
        self.volume       = 100
        self.hasPositions = false
        self.positions    = []
        
        //Read ID3 Info
        if let oId3Wrapper = Id3Wrapper(self.getValueAsString("path")){
            //Artist
            if let sArtist = oId3Wrapper.readArtist(){
                if(sArtist != ""){
                    self.artist = sArtist;
                }
            }
            //Title
            if let sTitle = oId3Wrapper.readTitle(){
                if(sTitle != ""){
                    self.title = sTitle;
                }
            }
            //Read Level
            if let sLevel = oId3Wrapper.readUserText("CloggingLevel"){
                if(sLevel != ""){
                    self.level = sLevel;
                }
            }
            
            //Read Tempo
            if let sTempo = oId3Wrapper.readUserText("LastTempo"){
                if(sTempo != ""){
                    if let dTempo = Double(sTempo) {
                        self.speed = lround(dTempo);
                    } else {
                        self.speed = 0;
                    }
                }
            }

//            //Read BPM
//            bpm = [Tools getBPMs:id3Tag];
            
            //Has Positions
            self.hasPositions = oId3Wrapper.hasPositions()
        }
    } //init
    
    func getValueAsString(_ property: String) -> String {
        switch property {
        case "path":
            return self.path.absoluteString.removingPercentEncoding!
//            path = path
//            return path
        case "title":
            return self.title
        case "artist":
            return self.artist
        case "level":
            return self.level
        case "duration":
            return self.duration
        case "speed":
            return "\(self.speed) %"
        case "bpm":
            return "\(self.bpm)"
        case "volume":
            return "\(self.volume)"
        case "hasPositions":
            return self.hasPositions ? "✓" : ""
        default:
            return ""
        }
    } //func getValueAsString
    
    func loadPositions(_ force: Bool = true) {
        if(force){
            //Force read? => Free previously read positions
            self.positions = []
        }
        
        //If positions have been read, don't do it again
        if(self.positions.count > 0){
            return
        }
        
        if let oId3Wrapper = Id3Wrapper(self.getValueAsString("path")){
            if let sPositions = oId3Wrapper.loadPositions() {
                if(sPositions == ""){
                    return;
                }
                
                //Split string into single lines ($LS = Line Separator)
                let aLines = sPositions.components(separatedBy: "$LS")
                
                for line in aLines{
                    //Split string into single cells ($CS = Cell Separator)
                    let aCells = line.components(separatedBy: "$CS")
                    self.positions.append(Position(name: aCells[0], comment: aCells[1], jumpTo: aCells[2], time: (UInt(aCells[3]) ?? 0)))
                }
            }
        }
    } //func loadPositions
    
}
