//
//  Window.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 15.11.19.
//

import Foundation

class Window : NSWindow {
    
    override func update() {
        super.update()

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
