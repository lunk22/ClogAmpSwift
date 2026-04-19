//
//  SettingsAboutViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 27.11.24.
//

import AppKit

class SettingsAboutViewController: NSViewController {

    override var preferredContentSize: NSSize {
        get { NSSize(width: 450, height: 300) }
        set { }
    }

    // MARK: VARS
    @objc let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
}
