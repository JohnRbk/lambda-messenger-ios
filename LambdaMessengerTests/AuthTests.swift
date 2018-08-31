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

class AuthTests: XCTestCase {
    
    let log = XCGLogger.default
    
    // Before each test, sign out the current user if necessary
    override func setUp() {
        super.setUp()
        if let _ = Auth.auth().currentUser {
            try? Auth.auth().signOut()
        }
    }
   
    
    func testCanCallAppSyncWithOIDCProvider() {
        let expectation = self.expectation(description: "callback")
        
        let email = TestUtils.randomEmail()
        let password = "abc123"
        
        TestUtils.createFirebaseUserWithEmail(email: email, password: password, displayName: "John")
            .then { _ -> Promises.Promise<Firebase.User> in
                return AuthManager.signIn(withEmail: email, password: password)
            }
            .then { user -> Promises.Promise<String> in
                return AuthManager.getIDToken(user: user)
            }
            .then { token in
                
                class Prov: AWSOIDCAuthProvider {
                    var token: String?
                    init (_ token: String){
                        self.token = token
                    }
                    func getLatestAuthToken() -> String {
                        return self.token!
                    }
                }
                
                let url = URL(string: "https://nyloqsxggnetpjbnhv62x5tyh4.appsync-api.us-east-1.amazonaws.com/graphql")!
                do {
                    let config = try AWSAppSyncClientConfiguration(url: url,
                                                                   serviceRegion: AWSRegionType.USEast1,
                                                                   oidcAuthProvider:  Prov(token))
                    
                    let client = try AWSAppSyncClient(appSyncConfig: config)
                    let lookup = LookupUserByEmailQuery(email: "fake@example.com")
                    client.fetch(query: lookup, resultHandler: { (result, error) in
                        XCTAssert(error == nil)
                        expectation.fulfill()
                    })
                } catch (let error) {
                    XCTFail(error.localizedDescription)
                }
            }
            .catch { error in
                XCTFail(error.localizedDescription)
            }
        
        self.waitForExpectations(timeout: 15, handler: nil)
    }
    
    
    
}
