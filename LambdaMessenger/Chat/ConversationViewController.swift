//
//  ConversationViewController.swift
//  Sheep Messenger
//
//  Created by Robokos, John on 7/16/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import CoreGraphics
import Promises
import Firebase
import XCGLogger

class ConversationViewController: UIViewController {
    var conversationId: String?
    var users: [User] = []
    var messages: [Message] = []
    let manager = ApiManager.default
    let log = XCGLogger.default
    var subscriptionWatcher: AWSAppSyncSubscriptionWatcher<NewMessageSubscription>?
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var newMessage: UITextField!
    @IBOutlet weak var inputBottomConstraint: NSLayoutConstraint!
    
    @objc func keyboardDisplayed(notification: NSNotification){
        print(notification)
        if let info = notification.userInfo, let rect = info[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            
            inputBottomConstraint.constant = rect.size.height + 5
        }
        
    }
    
    func scrollToBottom(){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.messages.count-1, section: 0)
            self.table.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDisplayed), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        self.table.dataSource = self
        self.newMessage.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let conversationId = self.conversationId else {
            fatalError("Required parameter conversationId not set")
        }
        
        newMessage.becomeFirstResponder()
        
        self.messages = []
        
        self.manager.getConversation(conversationId: conversationId)
            .then { conversation in
                self.messages = conversation.messages
                self.users = conversation.users
                // Show other user name in title
                if self.users.count > 0 {
                    self.title = self.users[0].displayName
                    self.navigationController?.navigationBar.topItem?.title = self.users[0].displayName
                }
                self.table.reloadData()
                self.scrollToBottom()
            }
            .then { _ in
                
                return self.manager.subscribe(conversationId: conversationId,
                                              callback: self.receivedNewMessage)
                
            }
            .then { sub in
                self.subscriptionWatcher = sub
            }
        
    }
    
    func receivedNewMessage(message: Message){
        self.messages.append(message)
        self.table.reloadData()
        self.scrollToBottom()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let sub = self.subscriptionWatcher {
            sub.cancel()
        }
    }
    
}


extension ConversationViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let i = indexPath.row
        //let section = indexPath.section
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell, let me = Auth.auth().currentUser {
            if let u = self.users.first(where: { $0.userId == messages[i].sender }) {
                if u.userId == me.uid {
                    cell.makeLeftAligned()
                }
                else {
                    cell.makeRightAligned()
                }
            }
            
            cell.message.text = messages[i].message
            
            return cell
        }

        
        
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView,
                   canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
}


extension ConversationViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let msg = self.newMessage.text,
            let cid = self.conversationId,
            let _ = Auth.auth().currentUser
            {
           
            self.manager.postMessage(conversationId: cid, message: msg)
//                .then{ _ in
//                    let dateString = Formatter.iso8601.string(from: Date())
//                    let m = UserMessage(message: msg, timestamp: dateString, sender: me.uid)
//                    self.messages.append(m)
//                }
//                .then{ _ in
//                    self.table.reloadData()
//                    self.scrollToBottom()
//                    self.newMessage.text = ""
//                }
        }
        return true
    }
}
