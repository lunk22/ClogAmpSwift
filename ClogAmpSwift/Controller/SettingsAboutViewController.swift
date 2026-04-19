//
//  SettingsAboutViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 27.11.24.
//

import AppKit

class SettingsAboutViewController: NSViewController {
    
    // MARK: VARS
    @objc let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
}
