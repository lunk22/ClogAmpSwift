//
//  TableView.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 10.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class TableView: NSTableView {
    
    weak var selectionDelegate: TableViewDelegate? = nil
    
    override func keyDown(with event: NSEvent) {
        if(event.keyCode == 36){
            //Enter
            self.selectionDelegate?.rowSelected()
        }else{
            super.keyDown(with: event)
        }
    }
    
    func scrollRowToVisible(row: Int, animated: Bool) {
        //See https://stackoverflow.com/questions/11767557/scroll-an-nstableview-so-that-a-row-is-centered
        if animated {
            guard let clipView = superview as? NSClipView,
                  let scrollView = clipView.superview as? NSScrollView else {

                    assertionFailure("Unexpected NSTableView view hiearchy")
                    return
            }

            let rowRect = rect(ofRow: row)
            var scrollOrigin = rowRect.origin

            let tableHalfHeight = clipView.frame.height * 0.5
            let rowRectHalfHeight = rowRect.height * 0.5

            scrollOrigin.y = (scrollOrigin.y - tableHalfHeight) + rowRectHalfHeight

            if scrollView.responds(to: #selector(NSScrollView.flashScrollers)) {
                scrollView.flashScrollers()
            }

            clipView.animator().setBoundsOrigin(scrollOrigin)

        } else {

            scrollRowToVisible(row)
        }
    }
    
}
