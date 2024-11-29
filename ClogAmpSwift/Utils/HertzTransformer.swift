//
//  HertzTransformer.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 30.07.24.
//

import Foundation

class HertzTransformer: ValueTransformer {
    
    //    override func valueClassForBinding(_ binding: String) -> AnyClass? {
    //        return NSString.self
    //    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if value == nil { return 0 }
        return "\(value!) Hz"
    }
    
}

extension NSValueTransformerName {
    static let hertzTransformer = NSValueTransformerName( rawValue: "HertzTransformer")
}
