//
//  Bundle.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 15.06.25.
//  Copyright © 2025 Pascal Roessel. All rights reserved.
//

import Foundation

extension Bundle {
    // Application name shown under the application icon.
    var applicationName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}
