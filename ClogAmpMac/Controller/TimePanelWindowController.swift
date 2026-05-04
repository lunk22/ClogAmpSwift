//
//  TimePanelWindowController.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 15.02.19.
//

import Foundation

class TimePanelWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        window?.setFrameAutosaveName("timeWindowAutosave")
        window?.delegate = self
        window?.isMovableByWindowBackground = true
        window?.titleVisibility = .hidden
        window?.standardWindowButton(.closeButton)?.isHidden = true
        window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window?.standardWindowButton(.zoomButton)?.isHidden = true

        super.windowDidLoad()
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        UserDefaults.standard.set(true, forKey: UserDefaults.Keys.prefTimeWindowOpen.rawValue)
    }

    func windowWillClose(_ notification: Notification) {
        guard !((NSApp.delegate as? AppDelegate)?.isTerminating ?? false) else { return }
        UserDefaults.standard.set(false, forKey: UserDefaults.Keys.prefTimeWindowOpen.rawValue)
    }

}
