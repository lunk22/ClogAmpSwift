//
//  PlayFromBeginning.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 14.06.25.
//  Copyright © 2025 Pascal Freundlich. All rights reserved.
//

import Foundation
import AppIntents

@available(macOS 13.0, *)
struct PlayFromBeginning: AppIntent {
    static var title: LocalizedStringResource = "Play from beginning"
    static var description = IntentDescription("Play the currently loaded song from the beginning")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        guard PlayerAudioEngine.shared.song != nil else { return .result() }
        PlayerAudioEngine.shared.seek(seconds: 0.0)
        PlayerAudioEngine.shared.play()
        return .result()
    }
}
