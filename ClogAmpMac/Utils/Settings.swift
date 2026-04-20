//
//  Defaults.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 23.11.23.
//

import Foundation
import AppKit

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

    // 0 = no offset, 1 = beats, 2 = seconds
    static var playPositionOffset: Int {
        var v = UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefPlayPositionOffset.rawValue)
        if v < 0 || v > 2 { v = 0 }
        return v
    }

    static var playPositionOffsetValue: Int {
        return UserDefaults.standard.integer(forKey: UserDefaults.Keys.prefPlayPositionOffsetValue.rawValue)
    }

    static var highlightPositionOffset: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefHighlightPositionOffset.rawValue)
    }

    static var showBeatCountdown: Bool {
        if UserDefaults.standard.value(forKey: UserDefaults.Keys.prefShowBeatCountdown.rawValue) == nil {
            UserDefaults.standard.set(false, forKey: UserDefaults.Keys.prefShowBeatCountdown.rawValue)
        }
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefShowBeatCountdown.rawValue)
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
    
    static var normalizeAudioBoost: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefNormalizeAudioBoost.rawValue)
    }
    
    static var normalizeAudioLevels: Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefNormalizeAudioLevels.rawValue)
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
    
    static var positionHighlightTextOnly: Bool {
        if UserDefaults.standard.value(forKey: UserDefaults.Keys.prefHighlightPositionTextOnly.rawValue) == nil {
            UserDefaults.standard.set(false, forKey: UserDefaults.Keys.prefHighlightPositionTextOnly.rawValue)
        }
        return UserDefaults.standard.bool(forKey: UserDefaults.Keys.prefHighlightPositionTextOnly.rawValue)
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

    static let monoAvailableFonts: [String] = {
        let manager = NSFontManager.shared
        return manager.availableFontFamilies.filter { family in
            let members = manager.availableMembers(ofFontFamily: family) ?? []
            return members.contains { member in
                guard let traitMask = member[3] as? Int else { return false }
                return (traitMask & Int(NSFontTraitMask.fixedPitchFontMask.rawValue)) != 0
            }
        }.sorted()
    }()

    static var monoFontName: String {
        let v = UserDefaults.standard.string(forKey: UserDefaults.Keys.prefMonoFontName.rawValue) ?? ""
        return v.isEmpty ? "Menlo" : v
    }

    static let proportionalAvailableFonts: [String] = {
        let manager = NSFontManager.shared
        let fonts = manager.availableFontFamilies.filter { family in
            let members = manager.availableMembers(ofFontFamily: family) ?? []
            return members.contains { member in
                guard let traitMask = member[3] as? Int else { return false }
                return (traitMask & Int(NSFontTraitMask.fixedPitchFontMask.rawValue)) == 0
            }
        }.sorted()
        return ["System"] + fonts
    }()

    static var proportionalFontName: String {
        let v = UserDefaults.standard.string(forKey: UserDefaults.Keys.prefProportionalFontName.rawValue) ?? ""
        return v.isEmpty ? "System" : v
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

    // MARK: PDF Layout

    static let pdfAvailableFonts = ["Arial", "Helvetica", "Georgia", "Times New Roman", "Courier", "Monaco", "Palatino"]

    static var pdfFontFamily: String {
        let v = UserDefaults.standard.string(forKey: UserDefaults.Keys.pdfFontFamily.rawValue) ?? ""
        return v.isEmpty ? "Arial" : v
    }

    static var pdfTitleSize: Double {
        let v = UserDefaults.standard.double(forKey: UserDefaults.Keys.pdfTitleSize.rawValue)
        return v > 0 ? v : 2.5
    }

    static var pdfArtistSize: Double {
        let v = UserDefaults.standard.double(forKey: UserDefaults.Keys.pdfArtistSize.rawValue)
        return v > 0 ? v : 1.2
    }

    static var pdfSubheaderSize: Double {
        let v = UserDefaults.standard.double(forKey: UserDefaults.Keys.pdfSubheaderSize.rawValue)
        return v > 0 ? v : 1.0
    }

    static var pdfPositionNameSize: Double {
        let v = UserDefaults.standard.double(forKey: UserDefaults.Keys.pdfPositionNameSize.rawValue)
        return v > 0 ? v : 1.0
    }

    static var pdfCommentSize: Double {
        let v = UserDefaults.standard.double(forKey: UserDefaults.Keys.pdfCommentSize.rawValue)
        return v > 0 ? v : 1.0
    }

    static var pdfCellPadding: Double {
        let v = UserDefaults.standard.double(forKey: UserDefaults.Keys.pdfCellPadding.rawValue)
        return v > 0 ? v : 0.75
    }

    static var pdfHeaderSpacing: Double {
        guard UserDefaults.standard.object(forKey: UserDefaults.Keys.pdfHeaderSpacing.rawValue) != nil else {
            return 1.0
        }
        return UserDefaults.standard.double(forKey: UserDefaults.Keys.pdfHeaderSpacing.rawValue)
    }
}
