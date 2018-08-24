//
//  ComposeMessageViewController.swift
//  LambdaMessenger
//
//  Created by John Robokos on 8/9/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import Foundation
import UIKit
import Promises
import XCGLogger
import Firebase

class ComposeMessageViewController: UIViewController {
    
    private let log = XCGLogger.default
    
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var userTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()        
    }
    
    @IBAction func tappedDone(_ sender: Any) {
        
        let manager = ApiManager.default
//        self.log.info("email: \(Auth.auth().currentUser?.email)")
//        self.log.info("name: \(Auth.auth().currentUser?.displayName)")
//        self.log.info("phone: \(Auth.auth().currentUser?.phoneNumber)")
//        self.log.info("uid: \(Auth.auth().currentUser?.uid)")
//
        manager.lookupUserByPhoneNumber(phoneNumber: userTextField.text!)
            .then { user-> Promises.Promise<String> in                
                return manager.initiateConversation(others: [user.userId])
            }
            .then { conversationId in
               
                self.dismiss(animated: true, completion: {
                    NotificationCenter.default.post(name: DashboardViewController.Events.initiateConversationModalComplete.notification, object: conversationId)
                })
                
            }
            .catch{ error in
                self.log.error(error)
            }
    
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
