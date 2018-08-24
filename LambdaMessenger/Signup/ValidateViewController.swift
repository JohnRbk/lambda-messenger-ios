//
//  ValidateViewController.swift
//  Sheep Messenger
//
//  Created by Robokos, John on 7/5/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import FirebaseAuth
import XCGLogger
import Promises

class ValidateViewController: UIViewController {
    
    let log = XCGLogger.default
    
    var displayName: String?
    
    @IBOutlet weak var validationCode: UITextField!
    
    // https://firebase.google.com/docs/auth/ios/phone-auth?authuser=0
    @IBAction func go(_ sender: Any) {
        
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID"),
            let code = validationCode.text else {
                self.log.error("authVerificationID is not set")
                return
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code)
        
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                self.log.error(error)
                return
            }
            
            AuthManager.updateDisplayName(self.displayName!)
                .then{ user in
                    return AuthManager.getIDToken(forceRefresh: true, user: user)
                }
                .then{ _ in
                    return ApiManager.default.registerUserWithPhoneNumber()
                }
                .recover { error throws -> Promises.Promise<User> in
                    if let pn = Auth.auth().currentUser?.phoneNumber {
                        return ApiManager.default.lookupUserByPhoneNumber(phoneNumber: pn)
                    }
                    return Promises.Promise<User>(error)
                }
                .then{ _ in
                    self.performSegue(withIdentifier: "GoSegue", sender: self)
                }
                .catch{ error in
                    self.log.error(error)
                }
            
        }
        
        return
    }
}
