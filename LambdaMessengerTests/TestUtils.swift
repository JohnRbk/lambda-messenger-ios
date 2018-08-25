//
//  TestUtils.swift
//  LambdaMessengerTests
//
//  Created by John Robokos on 8/18/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import Foundation
import Firebase
import Promises

struct TestUtils{
    static func randomEmail(_ name: String? = nil) -> String {
        
        if let name = name {
            return "\(name)\(UUID().uuidString.lowercased())@example"
        }
        else {
            return "\(UUID().uuidString.lowercased())@example.com"
        }
        
    }
    
    struct TestUser: User {
        var displayName: String
        
        var userId: String
        
        var phoneNumber: String?
        
        var email: String?
        
    }
    
    static func randomTestUser(_ name: String? = nil) -> User {
        var userName = UUID().uuidString
        
        if let n = name, name == nil {
            userName = n
        }
        
        let u = TestUser(displayName: userName, userId: UUID().uuidString, phoneNumber: "+15552122222", email: TestUtils.randomEmail(name))
        
        return u
    }
    
    static func randomNumber<T : SignedInteger>(inRange range: ClosedRange<T> = 1...6) -> T {
        let length = Int64(range.upperBound - range.lowerBound + 1)
        let value = Int64(arc4random()) % length + Int64(range.lowerBound)
        return T(value)
    }
    
    static func createAndRegisterUser(_ user: User) -> Promises.Promise<User> {
        let password = "abc123"
        let p = TestUtils.createFirebaseUserWithEmail(
            email: user.email!,
            password: password,
            displayName: user.displayName)
            .then { fbUser -> Promises.Promise<Firebase.User> in
                print("Signing in as \(fbUser.email!)")
                return AuthManager.signIn(withEmail: fbUser.email!, password: password)
            }
            .then { _ -> Promises.Promise<User> in
                print("registering \(Auth.auth().currentUser?.email?.description)")
                return ApiManager.default.registerUserWithEmail()
            }
            .then { user -> User in
                try? Auth.auth().signOut()
                print("done")
                return user
        }
        return p
    }
    
    static func createAndRegisterUsers(_ users: [User]) -> Promises.Promise<[User]> {
        
        var promises: [Promises.Promise<User>] = []
        
        for user in users {
            let p = createAndRegisterUser(user)
            promises.append(p)
        }
        
        let uuu = Promises.Promise([]).reduce(promises) { (userAccum, nextUser) in
            return nextUser.then{ (u)  in
                userAccum + [u]
            }
            .then{ (users)  in
                users
            }
        }
        
        return uuu
        
        
    }
    
    // Utility function to generate a test user
    // Note that setting the displayName requires a token refresh
    static func createFirebaseUserWithEmail(email: String,
                                     password: String,
                                     displayName: String) -> Promises.Promise<Firebase.User> {
        
        let promise = Promises.Promise<Firebase.User> { fulfill, reject in
            print("Creating user with email \(email)")
            AuthManager.createUser(withEmail: email, password: password)
                .then { _ -> Promises.Promise<Firebase.User> in
                    return AuthManager.signIn(withEmail: email, password: password)
                }
                .then { user -> Promises.Promise<Firebase.User> in
                    return AuthManager.updateDisplayName(displayName, forUser: user)
                }
                .then{ user -> Promises.Promise<String> in
                    return AuthManager.getIDToken(forceRefresh: true, user: user)
                        .then{ _ in
                            fulfill(user)
                        }
                }                
                .catch{ error in
                    reject(error)
                }
                .always {
                    try? Auth.auth().signOut()
            }
            }

        return promise
        
    }
}
