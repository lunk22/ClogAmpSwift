//
//  UserDefaults.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 27.11.24.
//

import Foundation

extension UserDefaults {
    
    // https://stackoverflow.com/questions/73207435/how-can-i-reset-appstorage-data-when-an-app-storage-variable-is-0

    enum Keys: String, CaseIterable {

        // Player
        case countTimeDown
        
        // Equalizer Hz Values
        case eqFrequencyLowHz
        case eqFrequencyMidHz
        case eqFrequencyHighHz
        
        // Equalizer Values per Hz Band
        case eqFrequencyLow
        case eqFrequencyMid
        case eqFrequencyHigh
        
        // Filesystem URLs
        case musicFolderPath
        case pdfFolderPath
        case lastLoadedSongURL
        
        // Table Customization
        case songTableFontSize
        case positionTableFontSize
        
        // Settings - General
        case prefMonoFontSongs
        case prefMonoFontPositons
        
        case prefStartFocusFilter
        case prefFilterTitleFactor
        
        case prefAppearance
        
        case prefViewAfterSongLoad
        
        case prefSkipForwardSeconds
        case prefSkipBackSeconds
        case prefColorPlayerState
        case prefAutoDetermineBPM
        
        case prefBpmLowerBound
        case prefBpmUpperBound
        
        // Settings - Positions
        case prefPlayPositionOnSelection
        
        case prefShowBeatsInPositionTable
        case prefBeatsChangeBehaviour
        
        case prefHighlightPosition
        case prefPositionHighlightColor
        case prefPositionTextColor
        
        case prefAddPositionBehaviour
        case prefAddPositionOffset
        
        case prefUpdateNameMatchingPositions
        case prefLoopDelay
        
        // Settings - Icon
        case AppIconName
        
        // NOT AVAILABLE IN SETTINGS
        case prefAudioMetering // defaults write de.pascalroessel.ClogAmpSwift prefAudioMetering -bool true
    }

    func reset() {
        Keys.allCases.forEach { removeObject(forKey: $0.rawValue) }
    }

}
