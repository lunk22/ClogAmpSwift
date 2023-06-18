//
//  Tools.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 13.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import Foundation

public func delayWithSeconds(_ seconds: Double, closure: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, qos: .userInitiated) {
        closure()
    }
}
