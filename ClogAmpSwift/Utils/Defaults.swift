//
//  Defaults.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 23.11.23.
//  Copyright © 2023 Pascal Freundlich. All rights reserved.
//

import Foundation

class Defaults {
    
    static var appearance: Int {
        var prefAppearance = UserDefaults.standard.integer(forKey: "prefAppearance")
        if(prefAppearance < 0 || prefAppearance > 2){
            prefAppearance = 0
        }
        return prefAppearance
    }
    
    static var appIconName: String? {
        return UserDefaults.standard.string(forKey: "AppIconName")
    }
    
    static var autoDetermineBpm: Bool {
        return UserDefaults.standard.bool(forKey: "prefAutoDetermineBPM")
    }
    
    static var bpmLowerBound: Int {
        var prefBpmLowerBound = UserDefaults.standard.integer(forKey: "prefBpmLowerBound")
        if prefBpmLowerBound == 0 {
            prefBpmLowerBound = 70
        }
        return prefBpmLowerBound
    }
    
    static var bpmUpperBound: Int{
        var prefBpmUpperBound = UserDefaults.standard.integer(forKey: "prefBpmUpperBound")
        if prefBpmUpperBound == 0 {
            prefBpmUpperBound = 140
        }
        return prefBpmUpperBound
    }
    
    static var colorizedPlayerState: Bool {
        return UserDefaults.standard.bool(forKey: "prefColorPlayerState")
    }
    
    static var countdownTime: Bool {
        return UserDefaults.standard.bool(forKey: "countTimeDown")
    }
    
    static var filterTitleFactor: Double {
        var factor = UserDefaults.standard.double(forKey: "prefFilterTitleFactor")
        if factor == 0 {
            factor = 1
        }
        return factor
    }
    
    static var focusFilterOnAppStart: Bool {
        return UserDefaults.standard.bool(forKey: "prefStartFocusFilter")
    }
    
    static var folderPathMusic: String? {
        return UserDefaults.standard.string(forKey: "musicFolderPath")
    }
    
    static var folderPathPDF: String? {
        return UserDefaults.standard.string(forKey: "pdfFolderPath")
    }
    
    static var lastLoadedSongURL: String? {
        return UserDefaults.standard.string(forKey: "lastLoadedSongURL")
    }
    
    static var loopDelay: Double {
        return UserDefaults.standard.double(forKey: "prefLoopDelay")
    }
    
    static var playPositionOnSelection: Bool {
        return UserDefaults.standard.bool(forKey: "prefPlayPositionOnSelection")
    }
    
    static var positionTableFontSize: Int {
        var fontSize = UserDefaults.standard.integer(forKey: "positionTableFontSize")
        if(fontSize == 0){
            fontSize = 12
        }
        return fontSize
    }
    
    static var positionTableMonoFont: Bool {
        return UserDefaults.standard.bool(forKey: "prefMonoFontPositons")
    }
    
    static var positionTableShowBeats: Bool {
        return UserDefaults.standard.bool(forKey: "prefShowBeatsInPositionTable")
    }
    
    static var skipForward: Int {
        var prefSkipForwardSeconds = UserDefaults.standard.integer(forKey: "prefSkipForwardSeconds")
        if prefSkipForwardSeconds == 0 {
            prefSkipForwardSeconds = 5
        }
        return prefSkipForwardSeconds
    }
    
    static var skipBack: Int {
        var prefSkipBackSeconds = UserDefaults.standard.integer(forKey: "prefSkipBackSeconds")
        if prefSkipBackSeconds == 0 {
            prefSkipBackSeconds = 5
        }
        return prefSkipBackSeconds
    }
    
    static var songTableFontSize: Int {
        var fontSize = UserDefaults.standard.integer(forKey: "songTableFontSize")
        if(fontSize == 0){
            fontSize = 12
        }
        return fontSize
    }
    
    static var songTableMonoFont: Bool {
        return UserDefaults.standard.bool(forKey: "prefMonoFontSongs")
    }
    
    static var viewAfterSongLoad: Int {
        var prefViewAfterSongLoad = UserDefaults.standard.integer(forKey: "prefViewAfterSongLoad")
        if(prefViewAfterSongLoad < 0 || prefViewAfterSongLoad > 2){
            prefViewAfterSongLoad = 0
        }
        return prefViewAfterSongLoad
    }
}
