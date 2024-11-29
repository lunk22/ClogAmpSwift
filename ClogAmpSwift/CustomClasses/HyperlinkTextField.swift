//
//  HyperlinkTextField.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 29.11.24.
//


import Cocoa
import AppKit

@IBDesignable
class HyperlinkTextField: NSTextField {
    @IBInspectable var href: String = ""
    
    override func awakeFromNib() {
        super.viewWillDraw()
        
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: NSColor.linkColor,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single
        ]
        self.attributedStringValue = NSAttributedString(string: self.stringValue, attributes: attributes)
    }
        
//    override func
    
//    override func mouseEntered(theEvent: NSEvent) {
//        //
//    }
    
    override func mouseDown(with: NSEvent) {
        if let url = URL(string: self.href) {
            NSWorkspace.shared.open(url)
        }
    }
}
