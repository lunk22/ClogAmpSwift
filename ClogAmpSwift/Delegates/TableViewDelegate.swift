//
//  TableViewDelegate.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 10.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

protocol TableViewDelegate: NSTableViewDelegate {
    func rowSelected()
}
