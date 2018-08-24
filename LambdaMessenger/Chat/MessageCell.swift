//
//  MessageCell.swift
//  LambdaMessenger
//
//  Created by John Robokos on 8/24/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import Foundation

class MessageCell: UITableViewCell {
    
    
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var message: UITextView!
    
    func makeLeftAligned(){
        self.leadingConstraint.isActive = true
        self.trailingConstraint.isActive = false
        self.message.textAlignment = .left
    }
    
    func makeRightAligned(){
        self.leadingConstraint.isActive = false
        self.trailingConstraint.isActive = true
        self.message.textAlignment = .right
    }

}
