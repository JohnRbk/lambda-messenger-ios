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
    var leftAligned = true

    override func layoutSubviews() {
        super.layoutSubviews()
        if leftAligned {
            self.leadingConstraint.isActive = true
            self.trailingConstraint.isActive = false
            self.message.textAlignment = .left
        } else {
            self.leadingConstraint.isActive = false
            self.trailingConstraint.isActive = true
            self.message.textAlignment = .right
        }

    }

    func makeLeftAligned() {
        leftAligned = true

    }

    func makeRightAligned() {
        leftAligned = false
    }

}
