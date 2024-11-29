//
//  DecibelTransformer.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 30.07.24.
//

import Foundation

class DecibelTransformer: ValueTransformer {

//    override func valueClassForBinding(_ binding: String) -> AnyClass? {
//        return NSString.self
//    }

    override func transformedValue(_ value: Any?) -> Any? {
        if value == nil { return 0.0 }
        return "\(Int(roundf(value as! Float))) dB"
    }

}

extension NSValueTransformerName {
    static let decibelTransformer = NSValueTransformerName( rawValue: "DecibelTransformer")
}
