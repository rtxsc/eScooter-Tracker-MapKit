//
//  ViewController.swift
//  eScooter Tracker MapKit
//
//  Created by Yazid on 20/04/2020.
//  Copyright © 2020 UiTM Kampus Samarahan Cawangan Sarawak. All rights reserved.
//

import UIKit
import MapKit
import PubNub

public struct HereNowPayload: Codable {
  public let totalOccupancy: Int
  public let totalChannels: Int
  public let channels: [String: HereNowChannelsPayload]
  public let uuids: [String]
}

public struct HereNowChannelsPayload: Codable {
  public let occupancy: Int
  public let uuids: [HereNowUUIDPayload]
}

public struct HereNowUUIDPayload: Codable {
  public let uuid: String
  public let state: [String: AnyJSON]?
}

struct userPayload: Codable,JSONCodable{
    var name: String
    var currentCredit: Double
    var userActivation: Bool
    var u_act_from_API: String
    var forceStop: Bool
    var startRiding: String?
    var stopRiding: String?
    var description: String?
}



class ViewController: UIViewController {
    
    var pubnub: PubNub!
    let channels = ["robotronix"]
    let listener = SubscriptionListener(queue: .main)
    
  
   
    var unlockCost: Double = 2.0 // unlocking requires RM2 in eWallet
    var currentCredit: Double = 0.0
    var minimumCredit: Double = 0.0
    var targetValue: Double = 0
    var score = 0
    var round: Int = 0
    var handshakeAck: Bool = false
    var hslistenerFlag: Bool = true
    var isRiding: Bool = false
    var hasRode: Bool = false
    var hasPublishedCredit: Bool = false
    weak var rideDurationCounter: Timer?
    weak var handshakeListenerCounter: Timer?
    var handshakeListenerTicker: Int = 0

    var start: String = ""
    var globalStart: String = ""
    var stop: String = ""
    var scooterUUID: String = ""
    var code: String = ""
    
    @IBOutlet weak var scanQRButton: UIButton!
    @IBOutlet weak var unlockCodeButton: UIButton!
    @IBOutlet weak var rideNowButton: UIButton!
    @IBOutlet weak var stopRidingButton: UIButton!
    @IBOutlet weak var rideDuration: UILabel!
    @IBOutlet weak var rideState: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var target: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var roundLabel: UILabel!
    @IBOutlet weak var currentCreditLabel: UILabel!
    @IBOutlet weak var scooterInUseLabel: UILabel!
    @IBOutlet weak var waitForAckLabel: UILabel!
    
    fileprivate let locationManager:CLLocationManager = CLLocationManager()
       
       private let marker1 = MKPointAnnotation()
       private let marker2 = MKPointAnnotation()
       
       var lat = 1.583301
       var lon = 110.388393
    var s1_lat = 0.0
    var s1_lon = 0.0
    var coordinate: Array<Float> = Array()
       var shift_lat = 0.0 // running latitude
       var shift_lon = 0.0 // running longitude
       var radius = 0.001 // rotation radius
    
       var tick: Double! = 0.0
       var ticker: Double! = 0.0

       var shift: Double! = 0.0
       var initialLocation: CLLocation!
  
    var user = userPayload(name: "iPhone SE(2020)", currentCredit: 0.0, userActivation: false, u_act_from_API: "u_act_0", forceStop: false, startRiding: nil, stopRiding: nil, description: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        rideNowButton.isHidden = true
        let encoder = JSONEncoder()
        user.name = "Yazid"
        encoder.outputFormatting = .prettyPrinted

        stopRidingButton.isHidden = true
        startListeningToChannel()
        // Do any additional setup after loading the view.
        let roundedValue = slider.value.rounded()
        currentCredit = Double(roundedValue)
        
        if #available(iOS 13.0, *) {
        self.overrideUserInterfaceStyle = .dark
        }
        
        mapView.delegate = self

       locationManager.requestWhenInUseAuthorization()
       locationManager.desiredAccuracy = kCLLocationAccuracyBest
       locationManager.distanceFilter = kCLDistanceFilterNone
       locationManager.startUpdatingLocation()
       
       mapView.showsUserLocation = true
       // Set initial location
       initialLocation = CLLocation(latitude: lat, longitude: lon)
       mapView.centerToLocation(initialLocation)
       
       let roi = CLLocation(latitude: lat, longitude: lon)
       let region = MKCoordinateRegion(
         center: roi.coordinate,
         latitudinalMeters: 50000,
         longitudinalMeters: 60000)
       mapView.setCameraBoundary(
         MKMapView.CameraBoundary(coordinateRegion: region),
         animated: true)
       
       let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 200000)
       mapView.setCameraZoomRange(zoomRange, animated: true)
       
       var newPosition1 = CLLocationCoordinate2D(latitude: lat, longitude: lon)
       var newPosition2 = CLLocationCoordinate2D(latitude: lat, longitude: lon)
       
       // Add annotation to map.
       marker1.title = "sc1"
       marker1.coordinate = initialLocation.coordinate
       marker2.title = "sc2"
       marker2.coordinate = initialLocation.coordinate
     
      mapView.addAnnotation(marker1)
      mapView.addAnnotation(marker2)
       
         // Show artwork on map
         let label = PopUpLabel(
           title: "HQ Location",
           locationName: "eScooter HQ",
           discipline: "Building",
           coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
       mapView.addAnnotation(label)
   
     
/*
         let labelmarker1 = PopUpLabel(
                            title: "sc1",
                            locationName: "\(self!.marker1.coordinate.latitude), \(self!.marker1.coordinate.longitude)",
                            discipline: "Vehicle",
                            coordinate: newPosition1)
         self!.mapView.addAnnotation(labelmarker1)
         
        var labelmarker2 = PopUpLabel(
                      title: "sc2",
                      locationName: "\(self.marker2.coordinate.latitude), \(self.marker2.coordinate.longitude)",
                      discipline: "Vehicle",
                      coordinate: initialLocation.coordinate)

        self.mapView.addAnnotation(labelmarker1)
        self.mapView.addAnnotation(labelmarker2)
         */
        // Set timer of 5 seconds before beginning the animation.
      weak var timer: Timer?
      
      //in a function or viewDidLoad() --- start global timer for func timerAction
      timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
       
      func updatePosition() {
        // Set timer to run after 5 seconds.
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
        // Set animation to last 5 seconds.
        UIView.animate(withDuration: 5, animations: {

        // update new coordinates every 5 seconds (get real-time coordinate from payload)
//        newPosition1 = CLLocationCoordinate2D(latitude: self!.lat + self!.shift_lat, longitude: self!.lon + self!.shift_lon)
//        newPosition2 = CLLocationCoordinate2D(latitude: self!.lat - self!.shift_lat, longitude: self!.lon - self!.shift_lon)
            
            newPosition1 = CLLocationCoordinate2D(latitude: self!.lat , longitude: self!.lon)
            newPosition2 = CLLocationCoordinate2D(latitude: self!.lat - self!.shift_lat, longitude: self!.lon - self!.shift_lon)
            

//        labelmarker1.coordinate = newPosition1
//        labelmarker2.coordinate = newPosition2

        // Update annotation coordinate to be the destination coordinate
        self?.marker1.title = "sc1"
        self?.marker1.subtitle = "\(self!.marker1.coordinate.latitude), \(self!.marker1.coordinate.longitude)"
        self?.marker2.title = "sc2"
        self?.marker2.subtitle = "\(self!.marker2.coordinate.latitude), \(self!.marker2.coordinate.longitude)"
        self?.marker1.coordinate = newPosition1
        self?.marker2.coordinate = newPosition2
            
              }, completion: nil)
          }
      }
      // Start moving annotations every 5 seconds
      updatePosition()
    } // end of viewDidLoad
    

    func startListeningToChannel(){
        
        listener.didReceiveMessage = { message in
//             print("[Received from channel]: \(message)")
            let payload = message.payload
        
        for item in payload{
//            print("what i found:\(item.self)")
            if(item.0.stringOptional=="s1_latitude"){
                if (item.1.doubleOptional != nil){
                    self.lat = (item.self.1.doubleOptional ?? 0)
                }
            }
            if(item.0.stringOptional=="s1_longitude"){
               if (item.1.doubleOptional != nil){
                  self.lon = (item.self.1.doubleOptional ?? 0)
               }
           }
        }
//            print("coordinate of client-s1:\(self.lat),\(self.lon)")

        }// close listener
        
        
            
//        listener.didReceivePresence = { event in
//                print("Channel `\(event.channel)` has occupancy of \(event.occupancy)")
//                print("User(s) Joined: \(event.join)")
//                print("User(s) Left: \(event.leave)")
//                print("User(s) Timedout: \(event.timeout)")
//        }
//          listener.didReceiveStatus = { status in
//            switch status {
//            case .success(let connection):
//              if connection == .connected {
//                self.pubnub.publish(channel: self.channels[0], message: "Hello from \(self.pubnub.configuration.uuid)") { result in
//                  switch result {
//                  case .success(_):
//                    print(result.map {"TOMOT DONE THE job at \($0.timetoken.timetokenDate)"})
//                  case .failure(_):
//                    print("Oh-ohh")
//                  }
//                }
//              }
//            case .failure(let error):
//              print("Status Error: \(error.localizedDescription)")
//            }
//          }
          pubnub.add(listener)
          pubnub.subscribe(to: channels,
                        withPresence: true)
        
//        pubnub.hereNow(on: channels,
//                            includeUUIDs: false,
//                         also: true) { result in
//                         switch result {
//                         case let .success(response):
//                           print("Successful hereNow Response: \(response)")
//                         case let .failure(error):
//                           print("Failed hereNow Response: \(error.localizedDescription)")
//                         }
//                       }
     
    }
       // timer function to calculate lat/lon shift value
       @objc func timerAction(){
           tick += 1
           shift = tick / 10000
            // divisor in the expression `tick / 10`
            // controls the animation speed.
            shift_lon = radius * sin(tick / 10)
            shift_lat = radius * cos(tick / 10)
           }
    
    @objc func rideDurationTimer(){

        if isRiding {
            ticker += 1.0
            rideDuration.text = String(ticker)
            currentCredit -= 0.50
            if currentCredit <= minimumCredit{
                currentCredit = minimumCredit
            }
            currentCreditLabel.text = String(currentCredit.rounded())
            rideNow() // always crosscheck currentCredit state
        }
        else{
            ticker = 0.0
            rideDurationCounter?.invalidate()
        }

    }
    
    @IBAction func stopTheRide(){
        stop = stopRidingTime()
        isRiding = false
        ticker = 0.0
        rideDurationCounter?.invalidate()
        let title = "Stop Riding"
        let message = "You have stopped the riding!"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         let action = UIAlertAction(title: "Return", style: .default, handler: nil)
         
         alert.addAction(action)
         present(alert,animated: true, completion: nil)
        stopRidingButton.isHidden = true
        rideNowButton.isHidden = false
        scanQRButton.isHidden = false
        unlockCodeButton.isHidden = false
        slider.isHidden = false

        
        if hasPublishedCredit == true {
            self.pubnub.publish(channel: self.channels[0], message: userPayload(name: user.name, currentCredit: currentCredit, userActivation: false, u_act_from_API: "u_act_0", forceStop: true, startRiding: globalStart, stopRiding: stop, description: nil)) { result in
//            print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
            }
            hasPublishedCredit = false

        }
    }
    
    @IBAction func useCodeToUnlock(){
        promptForUnlockCode()

    }
  
    
    @IBAction func rideNow(){
        let title: String
        var message = "You eWallet amount is RM \(currentCredit.rounded())"

        if(currentCredit <= unlockCost){
            stop = stopRidingTime()
            isRiding = false
            rideState.text = "Halting"
            if hasRode{
                title = "Cannot proceed riding"
            }
            else{
                title = "Unable to ride scooter"
            }
            message += "\nCredit is too low!"
            displayAlert(title: title, message: message)
            
            self.pubnub.publish(channel: self.channels[0], message: userPayload(name: user.name, currentCredit: currentCredit, userActivation: false, u_act_from_API: "u_act_0", forceStop: false, startRiding: globalStart, stopRiding: stop, description: nil)) { result in
                        print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
                        }
        }
        else if(currentCredit <= minimumCredit){
            stop = stopRidingTime()
            isRiding = false
            rideState.text = "Aborted"
            title = "Unable to unlock scooter"
            message += "\nInsufficient Credit!"
            displayAlert(title: title, message: message)
            rideDurationCounter?.invalidate()
            
            self.pubnub.publish(channel: self.channels[0], message: userPayload(name: user.name, currentCredit: currentCredit, userActivation: false, u_act_from_API: "u_act_0", forceStop: false, startRiding: globalStart, stopRiding: stop, description: nil)) { result in
                        print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
                        }
        }
        else{
            isRiding = true
            stopRidingButton.isHidden = false
            rideState.text = "Riding"
            title = "Enjoy your ride!"
            message += "\nRide will end automatically once your credit has finished."
            print("Scooter is running for \(ticker!) seconds...\n")

            if hasPublishedCredit == false{
                print("Unlocking scooter now...\n")
                start =  startRidingTime()
                globalStart = start
                displayAlert(title: title, message: message)
                
           
                self.pubnub.publish(channel: self.channels[0], message:userPayload(name: user.name, currentCredit: currentCredit, userActivation: true, u_act_from_API: "u_act_1", forceStop: false, startRiding: start, stopRiding: nil, description: nil)) {
                    result in
                print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
                }
                hasPublishedCredit = true
                let delay = 1.0
                // initialize rideDurationCounter here
                rideDurationCounter = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(rideDurationTimer), userInfo: nil, repeats: true)
                hasRode = true
                rideNowButton.isHidden = true
                scanQRButton.isHidden = true
                unlockCodeButton.isHidden = true
                slider.isHidden = true
                
                
            }
        }
    }
    
    func displayAlert(title:String,message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Return", style: .default, handler: nil)
        alert.addAction(action)
        present(alert,animated: true, completion: nil)
    }
    
    func startRidingTime()->String{
        let startRiding = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        start = formatter.string(from: startRiding)
        return start
    }
    
    func stopRidingTime()->String{
         let stopRiding = Date()
         let formatter = DateFormatter()
         formatter.dateStyle = .medium
         formatter.timeStyle = .medium
         stop = formatter.string(from: stopRiding)
         return stop
     }

    
    @IBAction func relocateUser(){
        print("Relocating user...\n")
        mapView.centerToLocation(initialLocation)

    }
        

    @IBAction func sliderMoved(_ slider: UISlider){
        let roundedValue = slider.value.rounded()
        currentCredit = Double(roundedValue)
        currentCreditLabel.text = String(currentCredit)
    }
    
    @objc func keepOnListeningToHandshake(){
            handshakeListenerTicker += 1
            waitForAckLabel.text = String(handshakeListenerTicker)
            print("Count:\(handshakeListenerTicker)")
            listener.didReceiveMessage = { message in
            print("[Payload]: \(message.payload)")
            let hs = message.payload

            for item in hs{
//                print("found item:\(item.0)")
                self.handshakeAck = item.1.boolOptional ?? false
//                print("current HS:\(self.handshakeAck)")
            }

            print("[Handshake from]: \(message.publisher ?? "defaultUUID")")
                self.scooterUUID = message.publisher!
            }
        
        if(self.handshakeAck == true){
            handshakeListenerCounter?.invalidate()
            hslistenerFlag = false
            checkForHandshake()
        }
                
    }
    
    func checkForHandshake(){
        
        if(code == "5347"){
            self.pubnub.publish(channel: self.channels[0], message: [code,scooterUUID]) { result in
                          print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
                          }
            if(hslistenerFlag){
                handshakeListenerCounter = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(keepOnListeningToHandshake), userInfo: nil, repeats: true)
            }
           if(self.handshakeAck == true){
                hslistenerFlag = true
                handshakeListenerTicker = 0
               self.rideNowButton.isHidden = false
               self.slider.isHidden = false
               self.scooterInUseLabel.text = self.scooterUUID
           }
           else{
               print("Waiting for acknowledgement from client...")
           }
        }
       else{
           self.rideNowButton.isHidden = true
           self.slider.isHidden = true
       }
    }
    
    
    func promptForUnlockCode() {
        let userUUID = pubnub.configuration.uuid
        let input = UIAlertController(title: "Enter Unlock Code", message: "Unlock Code is the 4-digit number found on scooter dashboard.", preferredStyle: .alert)
        input.addTextField()
        
        let submitAction = UIAlertAction(title: "Unlock Now", style: .default) { [unowned input] _ in
            self.code = input.textFields![0].text!
            self.pubnub.publish(channel: self.channels[0], message: [self.code,userUUID]) { result in
                     print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
                     }
           
            print("Unlock code entered:\(self.code) + handshake:\(self.handshakeAck)")
            self.checkForHandshake()
            //Unlock code entered:<_UIAlertControllerTextField: 0x7fd8f2864400; frame = (7 6.5; 225 17.5); text = '1234'; opaque = NO; gestureRecognizers = <NSArray: 0x60000088e130>; layer = <CALayer: 0x600000748440>>
            // do something interesting with "answer" here
        }

        input.addAction(submitAction)

        present(input, animated: true)
    }
    
    
}// end of ViewController




extension ViewController: MKMapViewDelegate {
  // 1
  func mapView(
    _ mapView: MKMapView,
    viewFor annotation: MKAnnotation
  ) -> MKAnnotationView? {
    // 2
    guard let annotation = annotation as? PopUpLabel else {
      return nil
    }
    // 3
    let identifier = "Annotation"
    var view: MKMarkerAnnotationView
    // 4
    if let dequeuedView = mapView.dequeueReusableAnnotationView(
      withIdentifier: identifier) as? MKMarkerAnnotationView {
      dequeuedView.annotation = annotation
      view = dequeuedView
    } else {
      // 5
      view = MKMarkerAnnotationView(
        annotation: annotation,
        reuseIdentifier: identifier)
      view.canShowCallout = true
      view.calloutOffset = CGPoint(x: -10, y: 20)
      view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    }
    return view
  }
}

private extension MKMapView {

  func centerToLocation(
    _ location: CLLocation,
    regionRadius: CLLocationDistance = 500
  ) {
    let coordinateRegion = MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: regionRadius,
      longitudinalMeters: regionRadius)
    setRegion(coordinateRegion, animated: true)
  }
}

