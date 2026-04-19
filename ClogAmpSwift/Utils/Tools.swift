//
//  Tools.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 13.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import Foundation
import Cocoa
import HtmlToPdf
import UserNotifications
//import CryptoKit

public func createPDF(htmlString: String, fileName: String = "Export") {
    let savePanel = NSSavePanel()
    savePanel.canCreateDirectories = true
    savePanel.allowedContentTypes = [.pdf]
    savePanel.nameFieldStringValue = fileName
//    savePanel.title = "PDF"
    savePanel.begin(completionHandler: { result in
        if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
            Task {
                do {
                    try await htmlString.print(to: savePanel.url!)

                    let allowed = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                    
                    if allowed {
                        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        // Create a content object with the message to convey.
                        let content: UNMutableNotificationContent = UNMutableNotificationContent()
                        content.body = "\(fileName).pdf successfully created"
                        content.sound = .default
                        
//                        let inputString = "\(fileName)\(Date.now)"
//                        let inputData = Data(inputString.utf8)
//                        let hashed = SHA256.hash(data: inputData)
//                        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
                        
                        let request = UNNotificationRequest(identifier: "ClogAmpMac", content: content, trigger: nil)
                        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                        try await UNUserNotificationCenter.current().add(request)
                    }
                } catch {
                    
                }
            }
        }
    })
}

public func delayWithSeconds(_ seconds: Double, closure: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, qos: .default) {
        closure()
    }
}
