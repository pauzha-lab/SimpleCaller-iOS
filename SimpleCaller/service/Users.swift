//
//  Users.swift
//  SimeplCaller
//
//  Created by pzdev on 25/06/21.
//

import Foundation
import FirebaseAuth
import FirebaseMessaging
import FirebaseDatabase

struct User {
    let username: String
    let uid: String
    let fcmToken: String?
    let apnsToken: String?
    
    init(username: String, uid: String, fcmToken: String, apnsToken: String?) {
        self.username = username
        self.uid = uid
        self.fcmToken = fcmToken
        self.apnsToken = apnsToken
    }
}

class Users {
    
    static func save_user(username: String, uid: String, fcmToken: String, apnsToken: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(username, forKey: "username")
        userDefaults.set(fcmToken, forKey: "fcmToken")
        userDefaults.set(apnsToken, forKey: "apnsToken")
        userDefaults.set(uid, forKey: "uid")
    }
    
    static func current_user() -> User? {
        let userDefaults = UserDefaults.standard
        if let username = userDefaults.string(forKey: "username") {
            let user: User = User(
                username: username,
                uid: userDefaults.string(forKey: "uid")!,
                fcmToken: userDefaults.string(forKey: "fcmToken")!,
                apnsToken: userDefaults.string(forKey: "apnsToken")!
            )
            return user
        }
        return nil
    }
    
    static func saveFcmToken(fcmToken: String) {
        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")
        // update fcmtoken in databse
    }
    
    static func saveAPNSToken(fcmToken: String) {
        UserDefaults.standard.set(fcmToken, forKey: "apnsToken")
    }
    
    static func getAPNSToken() -> String? {
        if let apnsToken: String = UserDefaults.standard.string(forKey: "apnsToken") {
            return apnsToken
        }
        
        return nil
    }
    
    static func getFcmToken() -> String? {
        if let fcmToken: String = UserDefaults.standard.string(forKey: "fcmToken") {
            return fcmToken
        }
        
        return nil
    }
    
    static func updateDB(uid: String) {
        let _currentUser = self.current_user()
        let ref: DatabaseReference!
        ref = Database.database().reference(withPath: "users")
        let user = ["Username": _currentUser!.username, "APNSToken": _currentUser!.apnsToken]
        ref.child(uid).updateChildValues(user as [AnyHashable : Any])
    }
    
    static func fetchFcmToken() {
        Messaging.messaging().token { token, error in
          if let error = error {
            print("Error fetching FCM registration token: \(error)")
          } else if let token = token {
            print("FCM registration token: \(token)")
            Users.saveFcmToken(fcmToken: token)
            //self.fcmRegTokenMessage.text  = "Remote FCM registration token: \(token)"
          }
        }
    }
    
    static func register_user(_ Username: String, uid: String) {
        let fcmToken = self.getFcmToken()
        let apnsToken = self.getAPNSToken()
        let ref: DatabaseReference!
        ref = Database.database().reference(withPath: "users")
        ref.child(uid).setValue(["Username": Username, "APNSToken": apnsToken])
        self.save_user(username: Username, uid: uid, fcmToken: fcmToken!, apnsToken: apnsToken!)
    }
    
    static func saveUserFromDB(uid: String) {
        
        let ref: DatabaseReference!
        ref = Database.database().reference()
        ref.child("users").child(uid).observeSingleEvent(of: .value, with: { snapshot in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let username = value?["Username"] as? String ?? ""
            self.save_user(username: username, uid: uid, fcmToken: "", apnsToken: "")

          // ...
        }) { error in
          print(error.localizedDescription)
        }
       
    }
    
    static func removeUser() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "uid")
        userDefaults.removeObject(forKey: "username")
        userDefaults.removeObject(forKey: "fcmToken")
        userDefaults.removeObject(forKey: "apnsToken")
    }
    
}
