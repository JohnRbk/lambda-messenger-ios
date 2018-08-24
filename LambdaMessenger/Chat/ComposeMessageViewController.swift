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

        guard let introMessage = messageTextField.text, let phoneNumber = userTextField.text else {
            self.log.error("Required fields not set")
            return
        }
        
        manager.lookupUserByPhoneNumber(phoneNumber: phoneNumber)
            .then { user-> Promises.Promise<Message> in
                return manager.initiateConversation(others: [user.userId], message: introMessage)
            }
            .then { newConversationMessage in
               
                self.dismiss(animated: true, completion: {
                    NotificationCenter.default.post(name: DashboardViewController.Events.initiateConversationModalComplete.notification, object: newConversationMessage.conversationId)
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
