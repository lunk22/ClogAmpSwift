//
//  NotificationDelegate.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 21.11.24.
//  Copyright © 2024 Pascal Roessel. All rights reserved.
//


import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
