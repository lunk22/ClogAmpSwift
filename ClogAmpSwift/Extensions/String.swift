//
//  String.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 28.11.23.
//  Copyright © 2023 Pascal Freundlich. All rights reserved.
//

import Foundation

extension String {
    func isInteger() -> Bool {
        let numbers = CharacterSet(charactersIn: "0123456789")
        return CharacterSet(charactersIn: self).isSubset(of: numbers)
    }
    
    func asInteger() -> Int {
        if self != "" {
            if self.isInteger() {
                return Int(self)!
            } else {
                return 0
            }
        }
        
        return 0
    }
    
    func asTime() -> String {
        return self//.replacingOccurrences(of: "0", with: "O")
    }
}
