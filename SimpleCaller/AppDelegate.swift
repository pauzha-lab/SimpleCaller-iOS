//
//  AppDelegate.swift
//  SimeplCaller
//
//  Created by pzdev on 22/05/21.
//

import UIKit
import Firebase
import UserNotifications
import CallKit
import PushKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
    var callProvider = ProviderDelegate()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        
//        if #available(iOS 10.0, *) {
//          // For iOS 10 display notification (sent via APNS)
//          UNUserNotificationCenter.current().delegate = self
//
//          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//          UNUserNotificationCenter.current().requestAuthorization(
//            options: authOptions,
//            completionHandler: {_, _ in })
//        } else {
//          let settings: UIUserNotificationSettings =
//          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
//          application.registerUserNotificationSettings(settings)
//        }
//
//        application.registerForRemoteNotifications()
//
//        Messaging.messaging().delegate = self
        
        Database.database().isPersistenceEnabled = true
        
        let usersRef = Database.database().reference(withPath: "users")
        usersRef.keepSynced(true)

        self.registerForPushNotifications()
        self.voipRegistration()

        
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
//        // If you are receiving a notification message while your app is in the background,
//        // this callback will not be fired till the user taps on the notification launching the application.
//        // TODO: Handle data of notification
//        // With swizzling disabled you must let Messaging know about the message, for Analytics
//        // Messaging.messaging().appDidReceiveMessage(userInfo)
//        // Print message ID.
//        if let messageID = userInfo[gcmMessageIDKey] {
//          print("Message ID: \(messageID)")
//        }
//
//        // Print full message.
//        print(userInfo)
//      }
//
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//      // If you are receiving a notification message while your app is in the background,
//      // this callback will not be fired till the user taps on the notification launching the application.
//      // TODO: Handle data of notification
//
//      // With swizzling disabled you must let Messaging know about the message, for Analytics
//      // Messaging.messaging().appDidReceiveMessage(userInfo)
//
//      // Print message ID.
//      if let messageID = userInfo[gcmMessageIDKey] {
//        print("Message ID: \(messageID)")
//      }
//
//      // Print full message.
//      print(userInfo)
//
//      completionHandler(UIBackgroundFetchResult.newData)
//    }
//
//
//
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("Unable to register for remote notifications: \(error.localizedDescription)")
//    }
//
//      // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
//      // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
//      // the FCM registration token.
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        print("APNs token retrieved: \(deviceToken)")
//
//        // With swizzling disabled you must set the APNs token here.
//        // Messaging.messaging().apnsToken = deviceToken
//    }
    func registerForPushNotifications() {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) {
                    [weak self] granted, error in
                    guard let _ = self else {return}
                    guard granted else { return }
                    self?.getNotificationSettings()
            }
    }
    
    // Register for VoIP notifications
        func voipRegistration() {
            
            // Create a push registry object
            let mainQueue = DispatchQueue.main
            let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
            voipRegistry.delegate = self
            voipRegistry.desiredPushTypes = [PKPushType.voIP]
        }
        
        // Push notification setting
        func getNotificationSettings() {
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    UNUserNotificationCenter.current().delegate = self
                    guard settings.authorizationStatus == .authorized else { return }
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            } else {
                let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(settings)
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    
}

//@available(iOS 10, *)
//extension AppDelegate : UNUserNotificationCenterDelegate, CXProviderDelegate {
//
//    // Receive displayed notifications for iOS 10 devices.
//      func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        let userInfo = notification.request.content.userInfo
//
//        // With swizzling disabled you must let Messaging know about the message, for Analytics
//        // Messaging.messaging().appDidReceiveMessage(userInfo)
//
//        // ...
//
//        // Print full message.
//        print(userInfo)
//        print("message recevied 1")
//        reportIncomingCall()
//
//        // Change this to your preferred presentation option
//        completionHandler([[.alert, .sound]])
//      }
//
//      func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        let userInfo = response.notification.request.content.userInfo
//
//        // ...
//
//        // With swizzling disabled you must let Messaging know about the message, for Analytics
//        // Messaging.messaging().appDidReceiveMessage(userInfo)
//
//        // Print full message.
//        print(userInfo)
//        print("message recevied 2")
//        reportIncomingCall()
//
//        completionHandler()
//      }
//
//    func reportIncomingCall() {
//        let provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "SimpleCaller"))
//        provider.setDelegate(self, queue: nil)
//        let update = CXCallUpdate()
//        update.remoteHandle = CXHandle(type: .generic, value: "Pete Za")
//        provider.reportNewIncomingCall(with: UUID(), update: update, completion: { error in
//            if let error = error {
//                print("Error requesting CXSetMutedCallAction transaction: \(error)")
//            } else {
//                print("Requested CXSetMutedCallAction transaction successfully")
//            }
//        })
//    }
//
//    func providerDidReset(_ provider: CXProvider) {
//    }
//
//    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
//        print("Call answered")
//        action.fulfill()
//    }
//
//    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
//        print("Call declined")
//        action.fulfill()
//    }
//}


//extension AppDelegate: MessagingDelegate {
//
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        print("Firebase registration token: \(String(describing: fcmToken))")
//        Users.saveFcmToken(fcmToken: fcmToken!)
//
//        let dataDict:[String: String] = ["token": fcmToken ?? ""]
//        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
//
//      // TODO: If necessary send token to application server.
//      // Note: This callback is fired at each app startup and whenever a new token is generated.
//    }
//}

// MARK:- UNUserNotificationCenterDelegate
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("didReceive ======", userInfo)
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("willPresent ======", userInfo)
        completionHandler([.alert, .sound, .badge])
    }
}

extension AppDelegate : PKPushRegistryDelegate {
    
    // Handle updated push credentials
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        print("pushRegistry -> deviceToken :\(deviceToken)")
        
        if let apnsToken = Users.getAPNSToken(), apnsToken != deviceToken {
            Users.saveAPNSToken(fcmToken: deviceToken)
            
            if Auth.auth().currentUser != nil {
                Users.updateDB(uid: Auth.auth().currentUser!.uid)
            }
        }
        
    }
        
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry:didInvalidatePushTokenForType:")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        print(payload)
        
        DispatchQueue.main.async {
            completion()
        }
        
        _ = payload.dictionaryPayload["aps"] as? [String:Any] ?? [:]
        
        let call_payload = [
            "fromUser": payload.dictionaryPayload["fromUser"] as! String,
            "session_id": payload.dictionaryPayload["session_id"] as! String
        ]

        print(call_payload)
        self.callProvider.reportIncomingCall(payload: call_payload)
        
    }
    
}
