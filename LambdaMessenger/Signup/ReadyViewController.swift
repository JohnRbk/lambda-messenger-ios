//
//  ReadyViewController.swift
//  Sheep Messenger
//
//  Created by Robokos, John on 7/15/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit

class ReadyViewController: UIViewController {

    @IBAction func ready(_ sender: Any) {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

        let initialViewController = mainStoryboard.instantiateViewController(withIdentifier: "DashNav")

        present(initialViewController, animated: true, completion: nil)

    }
}
