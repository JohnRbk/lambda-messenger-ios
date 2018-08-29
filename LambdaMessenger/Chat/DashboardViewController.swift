//
//  DashboardViewController.swift
//  Sheep Messenger
//
//  Created by Robokos, John on 7/6/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import FirebaseAuth
import XCGLogger
import UserNotifications

extension DashboardViewController {
    func initializeEvents() {
        
        let nc = NotificationCenter.default
        
        nc.addObserver(self,
                       selector: #selector(DashboardViewController.initiateConversationModalComplete(_:)),
                       name: DashboardViewController.Events.initiateConversationModalComplete.notification,
                       object: nil)
    }
    
    @objc func initiateConversationModalComplete(_ notification: Notification) {
        if let cid = notification.object as? String {
            self.performSegue(withIdentifier: "ConversationSegue", sender: cid)
        } else {
            fatalError("Unknown annotation type")
        }
    }
}

class DashboardViewController: UITableViewController {
    
    let log = XCGLogger.default
    
    var conversations: [Conversation] = []
    
    let manager = ApiManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeEvents()
    }
    
    enum Events: String {
        case initiateConversationModalComplete = "initiateConversationModalComplete"
        
        var notification: Notification.Name {
            return Notification.Name(rawValue: self.rawValue )
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
      
        self.manager.getConversationHistory().then { conversations in
            self.conversations = conversations.filter({ c -> Bool in
                c.messages.count > 0
            })
            self.tableView.reloadData()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let application = UIApplication.shared
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        application.registerForRemoteNotifications()
    }
    
    @IBAction func tappedCompose(_ sender: Any) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let composeViewController = mainStoryboard.instantiateViewController(withIdentifier: "ComposeMessage") as! ComposeMessageViewController
        
        self.present(composeViewController, animated: true)
        
    }
    
    @IBAction func tappedSettings(_ sender: Any) {
        self.navigationController?.performSegue(withIdentifier: "SettingsSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ConversationViewController, let cid = sender as? String{
            vc.conversationId = cid
        }
        
    }
    
    
}


extension DashboardViewController /* UITableView */ {
    
    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        
        return conversations.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let i = indexPath.row
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        
        if let me = Auth.auth().currentUser,
            let otherPerson = self.conversations[i].users.first(where: { $0.userId != me.uid }),
            let phoneNumber = otherPerson.phoneNumber {
            let mostRecentMessage = self.conversations[i].messages.last!
            cell.textLabel?.text = "\(otherPerson.displayName) (\(phoneNumber))"
            cell.detailTextLabel?.text = mostRecentMessage.message
            return cell
        }
        
        self.log.error("not logged in?")
        return UITableViewCell()
        
        
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        
        let i = indexPath.row
        //let section = indexPath.section
        
        self.performSegue(withIdentifier: "ConversationSegue", sender: conversations[i].conversationId)
        
    }
}
