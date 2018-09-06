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

class PhoneNumberTextFieldDelegate: DependentTextFieldDelegate, FieldDependency {
    let phoneUtil = PhoneNumberUtil()
    override func validate(_ value: String) -> Bool {
        return phoneUtil.validate(value)
    }
}

class DisplayNameTextFieldDelegate: DependentTextFieldDelegate, FieldDependency {
    override func validate(_ value: String) -> Bool {
        return value.count >= 2
    }
}

class RegisterViewController: UIViewController {

    let log = XCGLogger.default

    let phoneUtil = PhoneNumberUtil()

    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var displayName: UITextField!

    var phoneNumberDelegate: PhoneNumberTextFieldDelegate?
    var displayNameDelegate: DisplayNameTextFieldDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        let enableButton: () -> Void = {
            self.goButton.isEnabled = true
        }
        let disableButton: () -> Void = {
            self.goButton.isEnabled = false
        }
        self.phoneNumberDelegate = PhoneNumberTextFieldDelegate(validStateCallback: enableButton, invalidStateCallback: disableButton)
        self.displayNameDelegate = DisplayNameTextFieldDelegate(validStateCallback: enableButton, invalidStateCallback: disableButton)

        self.phoneNumber.delegate = self.phoneNumberDelegate!
        self.displayName.delegate = self.displayNameDelegate!

        self.phoneNumberDelegate!.dependencies.append(self.displayNameDelegate!)
        self.displayNameDelegate!.dependencies.append(self.phoneNumberDelegate!)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.goButton.isEnabled = false
    }

    @IBAction func go(_ sender: Any) {

        self.goButton.isEnabled = false
        self.phoneNumber.isEnabled = false
        self.displayName.isEnabled = false
        self.activityIndicator.startAnimating()

        guard let num = self.phoneNumber.text,
            let parsedNum = phoneUtil.parse(num),
            let displayName = self.displayName.text else {
            return
        }

        func handler(verificationID: String?, error: Error?) {

            if let error = error {
                log.error(error)
                let alert = UIAlertController(title: "Validation Error",
                                              message: "Unable to validate your phone number. Please try again later.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))

                self.present(alert, animated: true)
                self.activityIndicator.stopAnimating()
                self.goButton.isEnabled = true
                self.displayName.text = ""
                self.phoneNumber.text = ""
                return
            }

            log.info("VerificationID: \(verificationID!)")

            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            self.performSegue(withIdentifier: "ValidateSegue", sender: self)
        }

        PhoneAuthProvider.provider().verifyPhoneNumber(parsedNum, uiDelegate: nil, completion: handler)

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let num = self.phoneNumber.text,
            let parsedNum = phoneUtil.parse(num),
            let displayName = self.displayName.text else {

                fatalError("data not valid in attempt to segue")
        }
        if let dest = segue.destination as? ValidateViewController {
            dest.displayName = displayName
            dest.phoneNumber = parsedNum

        }
    }

}
