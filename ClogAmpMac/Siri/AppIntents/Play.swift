//
//  Play.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 14.06.25.
//  Copyright © 2025 Pascal Roessel. All rights reserved.
//

import Foundation
import AppIntents

@available(macOS 13.0, *)
struct Play: AppIntent {
    static var title: LocalizedStringResource = "Play song"
    static var description = IntentDescription("Play the currently loaded song")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        guard PlayerAudioEngine.shared.song != nil else { return .result() }
        PlayerAudioEngine.shared.play()
        return .result()
    }
}
