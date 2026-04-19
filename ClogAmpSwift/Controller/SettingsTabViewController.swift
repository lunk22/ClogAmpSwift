//
//  TabViewController.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 27.11.24.
//

import AppKit
import Sparkle

class SettingsTabViewController : NSTabViewController {

    override func addTabViewItem(_ tabViewItem: NSTabViewItem) {
        super.addTabViewItem(tabViewItem)
        tabViewItem.tabView?.delegate = self
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)

        if let tabViewItem = tabViewItem {
            view.window?.title = tabViewItem.label
        }
    }
}
