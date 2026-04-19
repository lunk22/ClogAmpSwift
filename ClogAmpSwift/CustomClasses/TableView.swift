//
//  TableView.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 10.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class TableView: NSTableView, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    
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
    
    // See https://stackoverflow.com/questions/53241431/nstableview-tab-between-columns-and-move-to-next-row
    // handle tab and backtab in an editable view based tableView subclass
    // will also scroll the edited cell into view when tabbing into view that are outside the viewable area
    //ref https://developer.apple.com/documentation/appkit/nscontroltexteditingdelegate/1428898-control
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print(#function)

        //let whichControl = control //this is the tableView textField where the event
                                     //  happened. In this case it will only be the
                                     //  NSTableCellView located within this tableView
        let whichSelector = commandSelector //this is the event; return, tab etc

        //these are the keypresses we are interested in, tab, backtab, return/enter.
        let tabSelector = #selector( insertTab(_:) )
        //let returnSelector = #selector( insertNewline(_:) ) //use this if you need
                                                              //custom return/enter handling
        let backtabSelector = #selector( insertBacktab(_:) )

        //if the user hits tab, need to determine where they are. If it's in the last
        //  column, need to see if there is another row and if so, move to next
        //  row, col 0 and go into edit. If it's a backtab in the first column, need
        //  to wrap back to the last row, last col and edit
        if whichSelector == tabSelector {
            let row = self.row(for: textView)
            let col = self.column(for: textView)
            let lastCol = self.tableColumns.count - 1

            if col == lastCol { //we tabbed forward in the last column
//                let lastRow = self.numberOfRows(in: self)
//                var rowToEdit: Int!
//
//                if row < lastRow { //if we are above the last row, go to the next row
//                    rowToEdit = row + 1
//
//                } else { //if we are at the last row, last col, tab around to the first row, first col
//                    rowToEdit = 0
//                }
//
//                self.editColumn(0, row: rowToEdit, with: nil, select: true)
//                self.scrollRowToVisible(rowToEdit)
//                return true //tell the OS we handled the key binding
                return false
            } else {
                self.scrollColumnToVisible(col + 1)
            }

        } else if whichSelector == backtabSelector {
            let row = self.row(for: textView)
            let col = self.column(for: textView)

            if col == 0 { //we tabbed backward in the first column
//                let lastCol = self.tableColumns.count - 1
//                var rowToEdit: Int!
//
//                if row > 0 { //and we are after row zero, back up a row and edit the last col
//                    rowToEdit = row - 1
//
//                } else { // we are in row 0, col 0 so wrap forward to the last col, last row
//                    rowToEdit = self.transactionArray.count - 1
//                }
//
//                self.editColumn(lastCol, row: rowToEdit, with: nil, select: true)
//                self.scrollRowToVisible(rowToEdit)
//                self.scrollColumnToVisible(lastCol)
//                return true
                return false
            }  else {
                self.scrollColumnToVisible(col - 1)
            }
        }

        return false //let the OS handle the key binding
    }
    
}
