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

    override func viewDidAppear() {
        super.viewDidAppear()
        resizeWindowToSelectedTab(animated: false)
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)

        if let tabViewItem = tabViewItem {
            view.window?.title = tabViewItem.label
        }

        resizeWindowToSelectedTab(animated: true)
    }

    private func resizeWindowToSelectedTab(animated: Bool) {
        guard let window = view.window,
              selectedTabViewItemIndex < children.count else { return }

        _ = children[selectedTabViewItemIndex].view // ensure view is loaded
        let contentSize = children[selectedTabViewItemIndex].view.frame.size
        guard contentSize.height > 0 else { return }

        var windowFrame = window.frame
        let currentContentHeight = window.contentRect(forFrameRect: windowFrame).height
        let delta = contentSize.height - currentContentHeight
        guard abs(delta) > 0.5 else { return }

        windowFrame.size.height += delta
        windowFrame.origin.y    -= delta  // keep top edge fixed
        window.setFrame(windowFrame, display: true, animate: animated)
    }
}
