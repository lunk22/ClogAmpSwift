//
//  PasteboardWriter.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 18.11.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import Foundation

class PasteboardWriter: NSObject, NSPasteboardWriting {
    var path: String
    var index: Int
    
    init(path: String, at index: Int) {
        self.path = path
        self.index = index
    }
    
    func writableTypes(
        for pasteboard: NSPasteboard)
        -> [NSPasteboard.PasteboardType]
    {
        return [.string, .tableRowIndex]
    }

    func pasteboardPropertyList(
        forType type: NSPasteboard.PasteboardType) -> Any?
    {
        switch type {
        case .string:
            return path
        case .tableRowIndex:
            return index
        default:
            return nil
        }
    }
}
