//
//  QRScanViewController.swift
//  eScooter Tracker MapKit
//
//  Created by Yazid on 21/04/2020.
//  Copyright © 2020 UiTM Kampus Samarahan Cawangan Sarawak. All rights reserved.
//

import UIKit
import PubNub

class QRScanViewController: UIViewController {
    
    let pubnub: PubNub? = nil
    @IBOutlet weak var walletAmountLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    let channels = ["Robotronix"]
    let listener = SubscriptionListener(queue: .main)
    var currentWalletAmount: Double = 0.0
    var tries = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        stepper.wraps = false
        stepper.autorepeat = true
        stepper.minimumValue = 0
        stepper.maximumValue = 50
        // Do any additional setup after loading the view.
    }

    @IBAction func stepperValueChanged(_ stepper: UIStepper){
        currentWalletAmount = stepper.value
        walletAmountLabel.text = Double(currentWalletAmount).description
    }
    
    @IBAction func unlockNow(){
     
        tries += 1
        print("\n\nTries:\(tries)\nTrying to unlock the scooter with current eWallet amount\n")
        print("RM \(currentWalletAmount)")
        
//        self.pubnub!.publish(channel: self.channels[0], message: "wallet=\(currentWalletAmount)") { result in
//           print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
//        }
     }
    
    @IBAction func close(){
          dismiss(animated: true, completion: nil)
      }
}
