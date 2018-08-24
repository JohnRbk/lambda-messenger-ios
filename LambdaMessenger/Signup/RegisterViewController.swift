//
//  ViewController.swift
//  Sheep Messenger
//
//  Created by Robokos, John on 7/5/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import FirebaseAuth
import XCGLogger

extension RegisterViewController: UITextFieldDelegate {
   
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let num = textField.text {
            self.enableButtonIfPhoneNumberIsValid(num)
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let text = textField.text,
            let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange,
                                                       with: string)
            enableButtonIfPhoneNumberIsValid(updatedText)
        }
        
        return true
    }
    
    
}

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var displayName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.phoneNumber.delegate = self
    }
    
    let log = XCGLogger.default
    
    let phoneUtil = PhoneNumberUtil()
    
    func enableButtonIfPhoneNumberIsValid(_ num: String){
        log.info("Validating \(num)")
        if phoneUtil.validate(num) {
            self.goButton.isEnabled = true
        }
        else {
            self.goButton.isEnabled = false
        }
    }
    

    @IBAction func go(_ sender: Any) {
        
        self.goButton.isEnabled = false
        self.phoneNumber.isEnabled = false
        self.activityIndicator.startAnimating()
        
        guard let num = self.phoneNumber.text,
            let parsedNum = phoneUtil.parse(num),
            let displayName = self.displayName.text else {
            return
        }
        
        func handler(verificationID: String?, error:Error?){
            
            if let error = error {
                log.error(error)
                let alert = UIAlertController(title: "Validation Error", message: "We were unable to validate your phone number. Please try again later.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                self.present(alert, animated: true)
                return
            }
            
            log.info("VerificationID: \(verificationID!)")
            
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            self.performSegue(withIdentifier: "ValidateSegue", sender: self)
        }
        
        PhoneAuthProvider.provider().verifyPhoneNumber(parsedNum, uiDelegate: nil, completion: handler);
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? ValidateViewController {
            dest.displayName = self.displayName.text
        }
    }
    
}

