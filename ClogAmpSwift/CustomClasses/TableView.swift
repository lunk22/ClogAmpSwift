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
    
}
