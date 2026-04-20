//
//  NotificationDelegate.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 21.11.24.
//


import AppKit
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let path = response.notification.request.content.userInfo["pdfPath"] as? String {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
        completionHandler()
    }
}
