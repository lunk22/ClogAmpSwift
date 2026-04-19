//
//  CAMShortcuts.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 15.06.25.
//  Copyright © 2025 Pascal Roessel. All rights reserved.
//

import AppIntents

@available(macOS 13.0, *)
struct CAMShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: PlayFromBeginning(), phrases: ["Play \(.applicationName) from the beginning"])
        AppShortcut(intent: Play(), phrases: ["Play \(.applicationName)"])
        AppShortcut(intent: Pause(), phrases: ["Pause \(.applicationName)"])
        AppShortcut(intent: Stop(), phrases: ["Stop \(.applicationName)"])
    }
}
