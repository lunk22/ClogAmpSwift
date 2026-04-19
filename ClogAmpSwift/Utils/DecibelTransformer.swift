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
        guard let number = value as? NSNumber else { return "0 dB" }
        return "\(Int(roundf(number.floatValue))) dB"
    }

}

extension NSValueTransformerName {
    static let decibelTransformer = NSValueTransformerName( rawValue: "DecibelTransformer")
}
