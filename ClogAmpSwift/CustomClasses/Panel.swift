//
//  Panel.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 15.11.19.
//

import Foundation

class Panel : NSPanel {
    
    override func update() {
        super.update()

        if #available(OSX 10.14, *) {
            switch Settings.appearance {
                case 1:
                    self.appearance = NSAppearance(named: .darkAqua) // Dark
                    break
                case 2:
                    self.appearance = NSAppearance(named: .aqua)     // Light
                    break
                default:
                    self.appearance = nil                            // Inherit
            }
        }
    }
    
}
