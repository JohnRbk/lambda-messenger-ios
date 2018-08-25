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

class GreetingTextFieldDelegate: DependentTextFieldDelegate, FieldDependency {
    override func validate(_ value: String) -> Bool {
        return value.count >= 2
    }
}

class ComposeMessageViewController: UIViewController {
    
    private let log = XCGLogger.default
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var newUserPhoneNumber: UITextField!
    @IBOutlet weak var greeting: UITextField!
    
    let phoneUtil = PhoneNumberUtil()
    
    var phoneNumberDelegate: PhoneNumberTextFieldDelegate?
    var greetingDelegate: GreetingTextFieldDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let enableButton: () -> Void = {
            self.sendButton.isEnabled = true
        }
        let disableButton: () -> Void = {
            self.sendButton.isEnabled = false
        }
        self.phoneNumberDelegate = PhoneNumberTextFieldDelegate(validStateCallback: enableButton, invalidStateCallback: disableButton)
        self.greetingDelegate = GreetingTextFieldDelegate(validStateCallback: enableButton, invalidStateCallback: disableButton)
        
        self.newUserPhoneNumber.delegate = self.phoneNumberDelegate!
        self.greeting.delegate = self.greetingDelegate!
        
        self.phoneNumberDelegate!.dependencies.append(self.greetingDelegate!)
        self.greetingDelegate!.dependencies.append(self.phoneNumberDelegate!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.sendButton.isEnabled = false
    }
    
    @IBAction func tappedDone(_ sender: Any) {
        
        let manager = ApiManager.default

        guard let greetingText = greeting.text,
            let phoneNumber = newUserPhoneNumber.text,
            let parsedNum = self.phoneUtil.parse(phoneNumber) else {
            fatalError("Required fields not set")
            return
        }
        
        self.sendButton.isEnabled = false
        self.activityIndicator.startAnimating()
        
        manager.lookupUserByPhoneNumber(phoneNumber: parsedNum)
            .then { user in
                return manager.initiateConversation(others: [user.userId])
            }
            .then { cid in
                return manager.postMessage(conversationId: cid,
                                           message: greetingText)
                    .then{ _ in
                        return cid
                    }
            }
            .then { cid in
               
                self.dismiss(animated: true, completion: {
                    NotificationCenter.default.post(name: DashboardViewController.Events.initiateConversationModalComplete.notification, object: cid)
                })
                
            }
            .catch{ error in
                self.sendButton.isEnabled = false
                self.activityIndicator.stopAnimating()
                
                if let e = error as? LambdaMessengerError,
                    e == LambdaMessengerError.userNotFoundError {
                    let alert = UIAlertController(title: "User not found",
                                                 message: "Your friend \(parsedNum) doesn't have LambdaMessenger installed",
                                                 preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    
                    self.present(alert, animated: true)
                }
                else {
                    let alert = UIAlertController(title: "Error",
                                                 message: "An error was detected. Please try again later.",
                                                 preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    
                    self.present(alert, animated: true)
                }
                
                self.log.error(error)
            }
    
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
