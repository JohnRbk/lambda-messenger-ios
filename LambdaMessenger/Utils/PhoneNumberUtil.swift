//
//  PhoneNumberUtil.swift
//  LambdaMessenger
//
//  Created by John Robokos on 8/8/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import Foundation
import libPhoneNumberiOS
import XCGLogger

class PhoneNumberUtil {
    let phoneUtil = NBPhoneNumberUtil()
    let log = XCGLogger.default
    
    func validate(_ num: String) -> Bool {
        return parse(num) == nil ? false : true
    }
    
    func parse(_ num: String) -> String? {
        do {
            let phoneNumber: NBPhoneNumber = try phoneUtil.parse(num, defaultRegion: "US")
            let formattedString: String = try phoneUtil.format(phoneNumber, numberFormat: .E164)
            
            let numDigits = phoneNumber.nationalNumber.stringValue.count
            return numDigits == 10 ? formattedString : nil
        }
        catch let error as NSError {
            log.error(error)
            return nil
        }
    }
}
