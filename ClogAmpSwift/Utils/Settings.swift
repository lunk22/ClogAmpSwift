//
//  Defaults.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 23.11.23.
//

import Foundation

class Settings: NSObject {
    
    static var addPositionBehavior: Int {
        var prefAddPositionBehavior = UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefAddPositionBehaviour.rawValue)
        if(prefAddPositionBehavior < 0 || prefAddPositionBehavior > 2){
            prefAddPositionBehavior = 0
        }
        return prefAddPositionBehavior
    }

    static var addPositionOffset: Int {
        return UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefAddPositionOffset.rawValue)
    }

    static var appearance: Int {
        var prefAppearance = UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefAppearance.rawValue)
        if(prefAppearance < 0 || prefAppearance > 2){
            prefAppearance = 0
        }
        return prefAppearance
    }
    
    static var appIconName: String? {
        return UserDefaults.standard.string(forKey: UserDefaults.Keys.AppIconName.rawValue)
    }
    
    static var audioMetering: Bool {
//        return true
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefAudioMetering.rawValue)
    }
    
    static var autoDetermineBpm: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefAutoDetermineBPM.rawValue)
    }
    
    static var beatsChangeBehavior: Int {
        var prefBeatsChangeBehavior = UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefBeatsChangeBehaviour.rawValue)
        if(prefBeatsChangeBehavior < 0 || prefBeatsChangeBehavior > 1){
            prefBeatsChangeBehavior = 0
        }
        return prefBeatsChangeBehavior
    }
    
    static var bpmLowerBound: Int {
        var prefBpmLowerBound = UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefBpmLowerBound.rawValue)
        if prefBpmLowerBound == 0 {
            prefBpmLowerBound = 70
        }
        return prefBpmLowerBound
    }
    
    static var bpmUpperBound: Int{
        var prefBpmUpperBound = UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefBpmUpperBound.rawValue)
        if prefBpmUpperBound == 0 {
            prefBpmUpperBound = 140
        }
        return prefBpmUpperBound
    }
    
    static var preventSystemSleep: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefPreventSleepWhenActive.rawValue)
    }
    
    static var colorizedPlayerState: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefColorPlayerState.rawValue)
    }
    
    static var countdownTime: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.countTimeDown.rawValue)
    }
    
    static var eqFrequencyLow: Float {
        return UserDefaults.standard.float(forKey: UserDefaults.Keys.eqFrequencyLow.rawValue)
    }
    
    static var eqFrequencyLowHz: Int {
        var hzValue = UserDefaults.standard.integer(forKey: UserDefaults.Keys.eqFrequencyLowHz.rawValue)
        if hzValue == 0 {
            hzValue = 80
            UserDefaults.standard.set(hzValue, forKey: UserDefaults.Keys.eqFrequencyLowHz.rawValue)
        }
        return hzValue
    }
    
    static var eqFrequencyMid: Float {
        return UserDefaults.standard.float(forKey: UserDefaults.Keys.eqFrequencyMid.rawValue)
    }
    
    static var eqFrequencyMidHz: Int {
        var hzValue = UserDefaults.standard.integer(forKey: UserDefaults.Keys.eqFrequencyMidHz.rawValue)
        if hzValue == 0 {
            hzValue = 2500
            UserDefaults.standard.set(hzValue, forKey: UserDefaults.Keys.eqFrequencyMidHz.rawValue)
        }
        return hzValue
    }
    
    static var eqFrequencyHigh: Float {
        return UserDefaults.standard.float(forKey: UserDefaults.Keys.eqFrequencyHigh.rawValue)
    }
    
    static var eqFrequencyHighHz: Int {
        var hzValue = UserDefaults.standard.integer(forKey: UserDefaults.Keys.eqFrequencyHighHz.rawValue)
        if hzValue == 0 {
            hzValue = 12000
            UserDefaults.standard.set(hzValue, forKey: UserDefaults.Keys.eqFrequencyHighHz.rawValue)
        }
        return hzValue
    }
    
    static var filterTitleFactor: Double {
        var factor = UserDefaults.standard.double(forKey: UserDefaults.Keys.prefFilterTitleFactor.rawValue)
        if factor == 0 {
            factor = 1
        }
        return factor
    }
    
    static var focusFilterOnAppStart: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefStartFocusFilter.rawValue)
    }
    
    static var folderPathMusic: String? {
        return UserDefaults.standard.string(forKey: UserDefaults.Keys.musicFolderPath.rawValue)
    }
    
    static var folderPathPDF: String? {
        return UserDefaults.standard.string(forKey: UserDefaults.Keys.pdfFolderPath.rawValue)
    }
    
    static var lastLoadedSongURL: String? {
        return UserDefaults.standard.string(forKey: UserDefaults.Keys.lastLoadedSongURL.rawValue)
    }
    
    static var loopDelay: Double {
        return UserDefaults.standard.double(forKey: UserDefaults.Keys.prefLoopDelay.rawValue)
    }
    
    static var playPositionOnSelection: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefPlayPositionOnSelection.rawValue)
    }
    
    static var positionHighlight: Bool {
        if UserDefaults.standard.value(forKey: UserDefaults.Keys.prefHighlightPosition.rawValue) == nil {
            UserDefaults.standard.set(true, forKey: UserDefaults.Keys.prefHighlightPosition.rawValue)
        }
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefHighlightPosition.rawValue)
    }
    
    static var positionHighlightColor: NSColor {
        if let data = UserDefaults.standard.data(forKey: UserDefaults.Keys.prefPositionHighlightColor.rawValue) {
            if let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) {
                return color as NSColor
            }
        }
        
        return NSColor.systemOrange
    }
    
    static var positionTextColor: NSColor {
        if let data = UserDefaults.standard.data(forKey: UserDefaults.Keys.prefPositionTextColor.rawValue) {
            if let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) {
                return color as NSColor
            }
        }
        
        return NSColor.black
    }
    
    static var positionTableFontSize: Int {
        var fontSize = UserDefaults.standard.integer(forKey: UserDefaults.Keys.positionTableFontSize.rawValue)
        if(fontSize == 0){
            fontSize = 12
        }
        return fontSize
    }
    
    static var positionTableMonoFont: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefMonoFontPositons.rawValue)
    }
    
    static var positionTableShowBeats: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefShowBeatsInPositionTable.rawValue)
    }
    
    static var showEqualizer: Bool {
        return true;
//        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefShowEqualizer.rawValue)
    }
    
    static var skipForward: Int {
        var prefSkipForwardSeconds = UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefSkipForwardSeconds.rawValue)
        if prefSkipForwardSeconds == 0 {
            prefSkipForwardSeconds = 5
        }
        return prefSkipForwardSeconds
    }
    
    static var skipBack: Int {
        var prefSkipBackSeconds = UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefSkipBackSeconds.rawValue)
        if prefSkipBackSeconds == 0 {
            prefSkipBackSeconds = 5
        }
        return prefSkipBackSeconds
    }
    
    static var songTableFontSize: Int {
        var fontSize = UserDefaults.standard.integer(forKey: UserDefaults.Keys.songTableFontSize.rawValue)
        if(fontSize == 0){
            fontSize = 12
        }
        return fontSize
    }
    
    static var songTableMonoFont: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefMonoFontSongs.rawValue)
    }
    
    static var updateNameMatchingPositions: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefUpdateNameMatchingPositions.rawValue)
    }
    
    static var viewAfterSongLoad: Int {
        var prefViewAfterSongLoad = UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefViewAfterSongLoad.rawValue)
        if(prefViewAfterSongLoad < 0 || prefViewAfterSongLoad > 2){
            prefViewAfterSongLoad = 0
        }
        return prefViewAfterSongLoad
    }
}
