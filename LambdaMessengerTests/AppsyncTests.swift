//
//  AppsyncTests.swift
//  LambdaMessengerTests
//
//  Created by John Robokos on 8/10/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import XCTest
import XCGLogger
import Firebase
import Promises

@testable import LambdaMessenger

class AppsyncTests: XCTestCase {

    let log = XCGLogger.default
    
    // Before each test, sign out the current user if necessary
    override func setUp() {
        super.setUp()
        if let _ = Auth.auth().currentUser {
            try? Auth.auth().signOut()
        }
    }

    func testCanHandleMissingDisplayNameError(){
        
        let expectation = self.expectation(description: "callback")
        let email = TestUtils.randomEmail()
        let password = "abc123"
        let manager = ApiManager.default
        
        AuthManager.createUser(withEmail: email, password: password)
            .then { _ in
                return AuthManager.signIn(withEmail: email, password: password)
            }
            .then { _ in
                manager.registerUserWithEmail(fcmToken: "fcmToken")
            }
            .then { _ in
                XCTFail()
            }
            .catch { error in
                expectation.fulfill()
            }
        self.waitForExpectations(timeout: 10, handler: nil)
                
    }
    
    func testCanHandleAuthErrors() {
        let manager = ApiManager.default
        let expectation = self.expectation(description: "threw error")
        
        manager.registerUserWithEmail(fcmToken: "fcmToken").then { user  in
            print(user)
            XCTFail()
        }.catch {error in
            if let e = error as? AWSAppSyncClientError, let desc = e.errorDescription {
                XCTAssertTrue(desc.contains("401 unauthorized"))
                expectation.fulfill()
            }
            else {
                XCTFail()
            }
        }
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testCanCreateFirebaseUser() {
        let expectation = self.expectation(description: "callback")
        let email = TestUtils.randomEmail()
        let password = "abc123"
        TestUtils.createFirebaseUserWithEmail(email: email, password: password, displayName: "John")
            .then { (user)  in
                XCTAssertEqual(user.email, email)
                XCTAssertEqual(user.displayName, "John")
                XCTAssertEqual(Auth.auth().currentUser?.displayName, "John")
                Auth.auth().currentUser?.getIDTokenResult(completion: { (authTokenResult, _) in
                    XCTAssertNotNil(authTokenResult?.claims["name"])
                    XCTAssertEqual("John", authTokenResult?.claims["name"] as! String)
                    expectation.fulfill()
                })

            }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testCanLookupUserByEmailError(){
        let expectation = self.expectation(description: "callback")
        
        let manager = ApiManager.default
        
        let email = TestUtils.randomEmail()
        let password = "abc123"
        
        TestUtils.createFirebaseUserWithEmail(email: email, password: password, displayName: "John")
            .then { _ in
                return AuthManager.signIn(withEmail: email, password: password)
            }
            .then { _ -> Promises.Promise<User> in
                return manager.registerUserWithEmail(fcmToken: "fcmToken")
            }
            .then { _ -> Promises.Promise<User> in
                return manager.lookupUserByEmail(email: "fake@example.com")
            }
            .then { user in
                XCTFail()
            }.catch { error in
                if let apiManagerError = error as? LambdaMessengerError, apiManagerError.hashValue == LambdaMessengerError.userNotFoundError.hashValue{
                    expectation.fulfill()
                }
                else {
                    XCTFail()
                }
            }
    
        
        self.waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testCanRegisterUser() {
        let expectation = self.expectation(description: "callback")

        let manager = ApiManager.default

        let email = TestUtils.randomEmail()
        let password = "abc123"

        TestUtils.createFirebaseUserWithEmail(email: email, password: password, displayName: "John")
            .then { _ -> Promises.Promise<User> in
                return manager.registerUserWithEmail(fcmToken: "fcmToken")
            }
            .then { user in
                XCTAssertEqual(user.email, email)
                expectation.fulfill()
            }
            .catch { error in
                print(error)
            }

        self.waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testCanInitiateConversation() {
        let expectation = self.expectation(description: "callback")
        
        let manager = ApiManager.default
        
        let mike = TestUtils.randomTestUser()
        let john = TestUtils.randomTestUser()
        let password = "abc123"
                    
        TestUtils.createAndRegisterUsers([mike, john])
            .then { _ in
                return AuthManager.signIn(withEmail: mike.email!, password: password)
            }
            .then { _ in
                XCTAssertNotNil(Auth.auth().currentUser)
                XCTAssertEqual(Auth.auth().currentUser?.email, mike.email!)
            }
            .then { _ -> Promises.Promise<User> in
                self.log.info("Looking up user")
                return manager.lookupUserByEmail(email: john.email!)
            }
            .then { john -> Promises.Promise<String> in
                self.log.info("Initiating")
                return manager.initiateConversation(others: [john.userId])
            }
            .then { cid in                
                return manager.postMessage(conversationId: cid, message:"hello")
                    .then { _ -> Promises.Promise<Firebase.User> in
                        try? Auth.auth().signOut()
                        return AuthManager.signIn(withEmail: john.email!, password: password)
                    }
                    .then { _ -> Promises.Promise<Conversation> in
                        self.log.info("getting convo for user \(Auth.auth().currentUser?.uid), cid: \(cid)")
                        return manager.getConversation(conversationId: cid)
                    }
                    .then { convo in
                        XCTAssertEqual("hello", convo.messages[0].message)
                        expectation.fulfill()
                    }
            }
            .catch { error in
                self.log.error(error)
                XCTFail()
            }
        
        
        self.waitForExpectations(timeout: 15, handler: nil)
    }

    func testCanHandleSignInFailure() {
        let expectation = self.expectation(description: "callback")
        let signInUserPromise = AuthManager.signIn(withEmail: TestUtils.randomEmail(),
                                                  password: "abc123")

        signInUserPromise.then(on: DispatchQueue.main) { _ in
            XCTFail()
            }.catch { error in
                print(error)
                expectation.fulfill()
        }

        self.waitForExpectations(timeout: 5, handler: nil)
    }

    func testSubscription() {

        let manager = ApiManager.default

        let mike = TestUtils.randomTestUser()
        let john = TestUtils.randomTestUser()
        let password = "abc123"

        let expectation1 = self.expectation(description: "callback1")
        let expectation2 = self.expectation(description: "callback2")

        func onNewMessage(newMessage: Message){
            print("Received a subscription message!")
            if (newMessage.message == "hi") {
                expectation1.fulfill()
            }
            if (newMessage.message == "yo") {
                expectation2.fulfill()
            }
        }

        TestUtils.createAndRegisterUsers([mike, john])
            .then{ _ -> Promises.Promise<Firebase.User>  in
                return AuthManager.signIn(withEmail: mike.email!, password: password)
            }
            .then { _ -> Promises.Promise<User> in
                return manager.lookupUserByEmail(email: john.email!)
            }
            .then { john -> Promises.Promise<String> in
                return manager.initiateConversation(others: [john.userId])
            }
            .then { cid -> Promises.Promise<[String]> in
                
                return manager.subscribe(conversationId: cid, callback:onNewMessage)
                    .delay(2)
                    .then { sub in
                        let p1 = manager.postMessage(conversationId: cid, message: "hi")
                        let p2 = manager.postMessage(conversationId: cid, message: "yo")
                        return Promises.all([p1, p2])
                    }
            }
            .catch { error in
                self.log.error(error)
                XCTFail()
            }
        

        self.waitForExpectations(timeout: 20, handler: nil)

    }

}
