//
//  Pause.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 14.06.25.
//  Copyright © 2025 Pascal Roessel. All rights reserved.
//

import Foundation
import AppIntents

@available(macOS 13.0, *)
struct Pause: AppIntent {
    static let intentClassName = "Pause"

    static var title: LocalizedStringResource = "Pause song"
    static var description = IntentDescription("Pause the currently playing song")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        if(PlayerAudioEngine.shared.isPlaying()) {
            PlayerAudioEngine.shared.pause()
        }
        return .result()
    }
}
