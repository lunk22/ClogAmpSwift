//
//  String.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 28.11.23.
//  Copyright © 2023 Pascal Freundlich. All rights reserved.
//

import Foundation

extension String {
    var isInteger: Bool {
        let numbers = CharacterSet(charactersIn: "0123456789")
        return CharacterSet(charactersIn: self).isSubset(of: numbers)
    }
}
