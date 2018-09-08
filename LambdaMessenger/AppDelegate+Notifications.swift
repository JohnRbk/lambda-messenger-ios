//
//  AppDelegate+Notifications.swift
//  LambdaMessenger
//
//  Created by John Robokos on 8/29/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import XCGLogger

extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Handles notification received while app was in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("In willPresent")
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    // Handles notification received while app was in background
    // called after user tapped on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("In didReceive")
        
        guard let messageID = userInfo["gcm.message_id"],
            let conversationId = userInfo["conversationdId"] else {
                self.log.error(userInfo)
                if let data = userInfo["data"] as? [AnyHashable:Any] {
                    self.log.error(data["foo"])
                }
                
                return
        }
        
        // Print message ID.
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}



extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        self.log.info("Firebase registration token: \(fcmToken)")

        self.fcmToken = fcmToken
        
        if let savedToken = UserDefaults.standard.string(forKey: "fcmToken") {
            if fcmToken != savedToken {
                if let name = Auth.auth().currentUser?.displayName {
                    
                    ApiManager.default.updateUser(displayName: name, fcmToken: fcmToken)
                        .then { _ in
                            self.log.info("Updated FCM Token for user")
                            UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
                        }
                    
                }
            }
        } else {
            UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        }
        
       
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }

    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}
