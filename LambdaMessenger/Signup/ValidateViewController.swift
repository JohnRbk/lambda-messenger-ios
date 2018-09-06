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
import Firebase

extension ValidateViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if let text = textField.text,
            let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange,
                                                       with: string)
            if updatedText.count == 6 {
                self.validateCodeButton.isEnabled = true
            } else {
                self.validateCodeButton.isEnabled = false
            }
        }

        return true
    }

}

class ValidateViewController: UIViewController {

    let log = XCGLogger.default

    var displayName: String?
    var phoneNumber: String?

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var validationCode: UITextField!
    @IBOutlet weak var validateCodeButton: UIButton!

    @IBOutlet weak var instructions: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let phoneNumber = self.phoneNumber else {
            fatalError("Required parameter not set")
        }

        self.validationCode.delegate = self
        self.instructions.text = "Please type the verification code sent to \(phoneNumber)"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.validateCodeButton.isEnabled = false
    }

    // https://firebase.google.com/docs/auth/ios/phone-auth?authuser=0
    @IBAction func go(_ sender: Any) {
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        appDelegate.fcmToken

        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID"),
            let code = validationCode.text,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let fcmToken = appDelegate.fcmToken
        else {
                fatalError("required parameters were not set")
        }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code)

        self.activityIndicator.startAnimating()
        self.validateCodeButton.isEnabled = false
        self.validationCode.isEnabled = false
        var oldDisplayName: String?
        AuthManager.signIn(withCredential: credential)
            .then { _ -> Promises.Promise<Firebase.User> in
                oldDisplayName = Auth.auth().currentUser?.displayName
                return AuthManager.updateDisplayName(self.displayName!)
            }
            .then { user -> Promises.Promise<String> in
                // Firebase requires a token to be refreshed after updating the
                // displayName. Otherwise, the JWT token will be sent without
                // it, causing an Authentication error
                return AuthManager.getIDToken(forceRefresh: true, user: user)
            }
            .then { _ -> Promises.Promise<User> in
                return ApiManager.default.registerUserWithPhoneNumber(fcmToken: fcmToken)
            }
            .recover { error throws -> Promises.Promise<User> in
                if let pn = Auth.auth().currentUser?.phoneNumber {
                    return ApiManager.default.lookupUserByPhoneNumber(phoneNumber: pn)
                }
                return Promises.Promise<User>(error)
            }
            .then { user -> Promises.Promise<User> in
                if let registeredName = Auth.auth().currentUser?.displayName,
                    let originalName = oldDisplayName, registeredName != originalName {
                    return ApiManager.default.updateUser(displayName: registeredName, fcmToken: fcmToken)
                } else {
                    return Promises.Promise<User>(user)
                }
            }
            .then { _ in
                self.performSegue(withIdentifier: "GoSegue", sender: self)
            }
            .catch { error in
                self.activityIndicator.stopAnimating()
                self.validateCodeButton.isEnabled = true
                self.validationCode.isEnabled = true
                self.validationCode.text = ""
                let e = error as NSError
                if e.code == AuthErrorCode.invalidVerificationCode.rawValue {
                    let alert = UIAlertController(title: "Validation Error",
                                                  message: "Please check the validation code and try again",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true)
                } else {
                    let alert = UIAlertController(title: "Unknown Error",
                                                  message: "Please try again later",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }

                self.log.error(error)
            }

        return
    }
}
