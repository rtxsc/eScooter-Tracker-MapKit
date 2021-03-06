//
//  AppDelegate.swift
//  eScooter Tracker MapKit
//
//  Created by Yazid on 20/04/2020.
//  Copyright © 2020 UiTM Kampus Samarahan Cawangan Sarawak. All rights reserved.
//

import UIKit
import PubNub // <- Here is our PubNub module import.

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var pubnub: PubNub!
    var window: UIWindow?
    
    let pub_key = "pub-c-8f52ff44-41bb-422c-a0c0-a63167077c6d"
    let sub_key = "sub-c-cf845704-8def-11ea-8e98-72774568d584"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        PubNub.log.levels = [.all]
        PubNub.log.writers = [ConsoleLogWriter(), FileLogWriter()]

        var config = PubNubConfiguration(publishKey: pub_key, subscribeKey: sub_key)
        config.uuid = "Comot"
        pubnub = PubNub(configuration: config)
        
      
        if #available(iOS 13.0, *) {
          // no-op - UI created in scene delegate
        } else if let rootVC = self.window?.rootViewController as? ViewController {
            rootVC.pubnub = pubnub
        }
        else if let rootVC2 = self.window?.rootViewController as? QRScanViewController {
            rootVC2.pubnub = pubnub
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

