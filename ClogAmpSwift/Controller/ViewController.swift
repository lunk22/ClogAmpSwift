//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 29.01.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class ViewController : NSViewController {
    
    func delayWithSeconds(_ seconds: Double, closure: @escaping () -> ()) {
        Tools.delayWithSeconds(seconds, closure: closure)
    }
    
}
