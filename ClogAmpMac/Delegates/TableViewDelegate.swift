//
//  TableViewDelegate.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 10.02.19.
//

import AppKit

protocol TableViewDelegate: NSTableViewDelegate {
    func rowSelected()
    
    func rightClicked()
}
