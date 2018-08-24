//
//  AppDelegate.swift
//  Sheep Messenger
//
//  Created by Robokos, John on 7/5/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        // This is the main way to set progress view color
        UIPageControl.appearance().pageIndicatorTintColor = .lightGray
        UIPageControl.appearance().currentPageIndicatorTintColor = .blue
        UIPageControl.appearance().backgroundColor = .white
        
        // https://stackoverflow.com/questions/10428629/programmatically-set-the-initial-view-controller-using-storyboards
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        // Assuming your storyboard is named "Main"
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Add code here (e.g. if/else) to determine which view controller class (chooseViewControllerA or chooseViewControllerB) and storyboard ID (chooseStoryboardA or chooseStoryboardB) to send the user to
        if let user = Auth.auth().currentUser, let phone = user.phoneNumber{
            print("User: " + phone)
            let initialViewController = mainStoryboard.instantiateViewController(withIdentifier: "DashNav")
            self.window?.rootViewController = initialViewController
        }
        else {
            let initialViewController = mainStoryboard.instantiateViewController(withIdentifier: "RegisterView")
            self.window?.rootViewController = initialViewController
        }
        
            
        self.window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

