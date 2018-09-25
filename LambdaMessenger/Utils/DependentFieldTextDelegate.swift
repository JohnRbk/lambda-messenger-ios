//
//  DependentFieldTextDelegate.swift
//  LambdaMessenger
//
//  Created by John Robokos on 8/25/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import Foundation
import UIKit

protocol FieldDependency {
    var isValid: Bool { get }
}

class DependentTextFieldDelegate: NSObject, UITextFieldDelegate {
    var isValid: Bool = false {
        willSet {
            if newValue == true && !dependencies.contains(where: { $0.isValid == false}) {
                validStateCallback!()
            } else {
                invalidStateCallback!()
            }
        }
    }

    var dependencies: [FieldDependency] = []

    init (validStateCallback: @escaping () -> Void,
          invalidStateCallback: @escaping () -> Void) {
        self.validStateCallback = validStateCallback
        self.invalidStateCallback = invalidStateCallback
    }

    var validStateCallback: (() -> Void)?

    var invalidStateCallback: (() -> Void)?

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.isValid = false
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if let value = textField.text {
            self.isValid = validate(value)
        }
    }
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {

        if let text = textField.text, let textRange = Range(range, in: text) {

            let newValue = text.replacingCharacters(in: textRange, with: string)

            self.isValid = validate(newValue)
        }

        return true
    }

    func validate(_ value: String) -> Bool {
        return true
    }

}
