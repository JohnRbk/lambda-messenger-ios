//
//  ChatSessionViewController.swift
//  Sheep Messenger
//
//  Created by Robokos, John on 7/16/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import CoreGraphics
import Promises
import Firebase

class ChatSessionViewController: UIViewController {
    var conversationId: String?
    var users: [User] = []
    var messages: [Message] = []
    
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
        
        // Show other user name in title
        if self.users.count > 0 {
            self.title = self.users[0].displayName
            self.navigationController?.navigationBar.topItem?.title = self.users[0].displayName
        }
        
        let manager = ApiManager.default
        manager.getConversation(conversationId: conversationId)
            .then { conversation in
                self.messages = conversation.messages
                self.users = conversation.users
                self.table.reloadData()
                self.scrollToBottom()
            }
            .then { _ in
                manager.subscribe(conversationId: conversationId, callback: self.receivedNewMessage)                
            }
        
    }
    
    func receivedNewMessage(message: Message){
        self.messages.append(message)
        self.table.reloadData()
        self.scrollToBottom()
    }
    
}


extension ChatSessionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let i = indexPath.row
        //let section = indexPath.section

        let cell = tableView.dequeueReusableCell(withIdentifier: "Message2Cell", for: indexPath)

        
        if let u = self.users.first(where: { $0.userId == messages[i].sender }) {
            cell.textLabel?.text = u.displayName
        } else {
            cell.textLabel?.text = "Unknown Sender"
        }
        
        cell.detailTextLabel?.text = messages[i].message
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
}


extension ChatSessionViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let msg = self.newMessage.text,
            let cid = self.conversationId,
            let me = Auth.auth().currentUser
            {
           
            ApiManager.default.postMessage(conversationId: cid, message: msg)
                .then{ _ in
                    let dateString = Formatter.iso8601.string(from: Date())
                    let m = UserMessage(message: msg, timestamp: dateString, sender: me.uid)
                    self.messages.append(m)
                }
                .then{ _ in
                    self.table.reloadData()
                    self.scrollToBottom()
                    self.newMessage.text = ""
                }
        }
        return true
    }
}
