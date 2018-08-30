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
    
    @IBAction func sendButtonAction(_ sender: Any) {
        if let msg = self.newMessage.text,
            let cid = self.conversationId,
            let _ = Auth.auth().currentUser
        {
            
            _ = self.manager.postMessage(conversationId: cid, message: msg, sendPushNotifications: true)
            self.newMessage.text = ""
            
        }
    }
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var newMessage: UITextField!
    @IBOutlet weak var controlPaneBottomConstraint: NSLayoutConstraint!
    
    enum Events: String {
        case restartSub = "restartSub"
        
        var notification: Notification.Name {
            return Notification.Name(rawValue: self.rawValue )
        }
    }
    
    @objc func keyboardDisplayed(notification: NSNotification){
        self.log.info("Showing keyboard")
        if let info = notification.userInfo, let rect = info[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            
            controlPaneBottomConstraint.constant = rect.size.height - 34
        }
        
    }
    
    func initializeEvents() {
        
        let nc = NotificationCenter.default
        
        nc.addObserver(self,
                       selector: #selector(ConversationViewController.restartSub(_:)),
                       name: ConversationViewController.Events.restartSub.notification,
                       object: nil)
    }
    
    // This is called in ApiManager when a subscription error is detected
    // and we need to restart the subscription service.
    @objc func restartSub(_ notification: Notification) {
        self.log.info("In restartSub")
        getMessagesAndStartSubscription()
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
    
    func getMessagesAndStartSubscription(){
        guard let conversationId = self.conversationId,
            let me = Auth.auth().currentUser else {
                fatalError("Required parameters not set")
        }
        
        self.log.info("#################################################")
        self.log.info("userId: \(me.uid)");
        self.log.info("conversationId: \(conversationId)");
        self.log.info("#################################################")
        newMessage.becomeFirstResponder()
        
        self.messages = []
        self.manager.getConversation(conversationId: conversationId)
            .then { conversation in
                self.messages = conversation.messages
                self.users = conversation.users
                
                
                // Show other user name in title
                let convoUsers = self.users.filter({ $0.userId != me.uid })
                if convoUsers.count > 0 {
                    self.title = convoUsers.map({ $0.displayName }).joined(separator: ", ")
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getMessagesAndStartSubscription()
    }
    
    func receivedNewMessage(message: Message){
        self.log.info("Got a pubsub notification")
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
        
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: "MessageCell", for: indexPath) as? MessageCell,
            let me = Auth.auth().currentUser {
            
            cell.message.text = messages[i].message
            if messages[i].sender.userId == me.uid {
                cell.makeRightAligned()
            }
            else {
                cell.makeLeftAligned()
            }
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
        
        self.sendButtonAction(self)
        return true
    }
}
