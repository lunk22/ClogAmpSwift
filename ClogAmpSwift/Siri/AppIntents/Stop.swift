//
//  Stop.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 14.06.25.
//  Copyright © 2025 Pascal Roessel. All rights reserved.
//

import Foundation
import AppIntents

@available(macOS 13.0, *)
struct Stop: AppIntent {
    static let intentClassName = "Stop"

    static var title: LocalizedStringResource = "Stop song"
    static var description = IntentDescription("Stop the currently playing song")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        PlayerAudioEngine.shared.stop()
        return .result()
    }
}
