//
//  SettingsViewController.swift
//  Sheep Messenger
//
//  Created by Robokos, John on 7/15/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {
    
    @IBAction func signOut(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
        // Assuming your storyboard is named "Main"
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let initialViewController = mainStoryboard.instantiateViewController(withIdentifier: "RegisterView")
        
        present(initialViewController, animated: true, completion: nil)
        
        
    }
}
