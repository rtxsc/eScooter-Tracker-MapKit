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
import CoreLocation

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

struct gimmeAck: Codable,JSONCodable{
    var name: String
    var unlockCodeGiven: String
    var askingForAck: Bool
}

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    private var locationManager = CLLocationManager()

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
    var s_act: String?
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
    @IBOutlet weak var distanceToClientLabel: UILabel!
    @IBOutlet weak var userCoordinateLabel: UILabel!
        
    private let marker1 = MKPointAnnotation()
    private let marker2 = MKPointAnnotation()
    private let marker3 = MKPointAnnotation()
    // dummy user location far 1.582892,110.387988
    // dummy user location near 1.583263,110.388561

    var userLat = 0.0
    var userLon = 0.0
    
    var s1_lat = 0.0
    var s1_lon = 0.0
    var s2_lat = 0.0
    var s2_lon = 0.0
    var s3_lat = 0.0
    var s3_lon = 0.0
        
    var coordinate: Array<Float> = Array()
    var shift_lat = 0.0 // running latitude
    var shift_lon = 0.0 // running longitude
    var radius = 0.0005 // rotation radius

    var tick: Double! = 0.0
    var ticker: Double! = 0.0

    var shift: Double! = 0.0
    var currentLocation: CLLocation!
    var user = userPayload(name:"Anonymous" , currentCredit: 0.0, userActivation: false, u_act_from_API: "u_act_0", forceStop: false, startRiding: nil, stopRiding: nil, description: nil)
         
 
    override func viewDidLoad() {
        if #available(iOS 13.0, *) {
            self.overrideUserInterfaceStyle = .dark
            }
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
      

        getUserLocation()
        startListeningToChannel()
        rideNowButton.isHidden = true
        stopRidingButton.isHidden = true

        let roundedValue = slider.value.rounded()
        currentCredit = Double(roundedValue)
        
    
        var newPosition1 = CLLocationCoordinate2D(latitude: userLat, longitude: userLon)
        var newPosition2 = CLLocationCoordinate2D(latitude: userLat, longitude: userLon)
        var newPosition3 = CLLocationCoordinate2D(latitude: userLat, longitude: userLon)

        // Add annotation to map.
            
        currentLocation = CLLocation(latitude: userLat, longitude: userLon)
        marker1.title = "client-s1"
        marker1.coordinate = currentLocation.coordinate
        marker2.title = "client-s2"
        marker2.coordinate = currentLocation.coordinate
        marker3.title = "client-s3"
        marker2.coordinate = currentLocation.coordinate
        mapView.addAnnotation(marker1)
        mapView.addAnnotation(marker2)
        mapView.addAnnotation(marker3)

         // Show artwork on map
         let label = PopUpLabel(
           title: "User",
           locationName: "Anonymous User",
           discipline: "User",
           coordinate: CLLocationCoordinate2D(latitude: userLat, longitude: userLon))
       mapView.addAnnotation(label)
        
        let labelmarker3 = PopUpLabel(
                             title: "sc3",
                             locationName: "\(self.marker3.coordinate.latitude), \(self.marker3.coordinate.longitude)",
                             discipline: "Vehicle",
                             coordinate: currentLocation.coordinate)

        self.mapView.addAnnotation(labelmarker3)

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
                      coordinate: currentLocation.coordinate)

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
        newPosition1 = CLLocationCoordinate2D(latitude: self!.s1_lat , longitude: self!.s1_lon)
        newPosition2 = CLLocationCoordinate2D(latitude: self!.s2_lat, longitude: self!.s2_lon - self!.shift_lon)
        newPosition3 = CLLocationCoordinate2D(latitude: self!.userLat - self!.shift_lat, longitude: self!.userLon - self!.shift_lon)
            
//        labelmarker1.coordinate = newPosition1
//        labelmarker2.coordinate = newPosition2

        // Update annotation coordinate to be the destination coordinate
        self?.marker1.title = "client-s1"
        self?.marker1.subtitle = "\(self!.marker1.coordinate.latitude), \(self!.marker1.coordinate.longitude)"
        self?.marker2.title = "client-s2"
        self?.marker2.subtitle = "\(self!.marker2.coordinate.latitude), \(self!.marker2.coordinate.longitude)"
        self?.marker3.title = "client-s3"
        self?.marker3.subtitle = "\(self!.marker3.coordinate.latitude), \(self!.marker3.coordinate.longitude)"
        self?.marker1.coordinate = newPosition1
        self?.marker2.coordinate = newPosition2
        self?.marker3.coordinate = newPosition3
              }, completion: nil)
          }
      }
      // Start moving annotations every 5 seconds
      updatePosition()
    } // end of viewDidLoad
    
    func getUserLocation(){
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        print("Getting location from GPS!")
        locationManager.delegate = self
    }
    func locationManager(_ manager: CLLocationManager,didUpdateLocations locations: [CLLocation]){
        if let location = locations.last {
            userLat = location.coordinate.latitude
            userLon = location.coordinate.longitude
            let formattedLat = String(format: "%.4f", userLat)
            let formattedLon = String(format: "%.4f", userLon)
            userCoordinateLabel.text = "\(formattedLat), \(formattedLon)"
        }
       
        currentLocation = CLLocation(latitude: userLat, longitude: userLon)
        
        let roi = CLLocation(latitude: userLat, longitude: userLon)
        let region = MKCoordinateRegion(
          center: roi.coordinate,
          latitudinalMeters: 50000,
          longitudinalMeters: 60000)
        mapView.setCameraBoundary(
          MKMapView.CameraBoundary(coordinateRegion: region),
          animated: true)
        
        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 200000)
        mapView.setCameraZoomRange(zoomRange, animated: true)
        mapView.delegate = self
        mapView.showsUserLocation = true // enable pulsing blue dot
        mapView.centerToLocation(currentLocation)

    }
    

    func startListeningToChannel(){
        
        listener.didReceiveMessage = { message in
//             print("[Received from channel]: \(message)")
            let payload = message.payload
        
        for item in payload{
//            print("what i found:\(item.self)")
            if(item.0.stringOptional=="s1_latitude"){
                if (item.1.doubleOptional != nil){
                    self.s1_lat = (item.self.1.doubleOptional ?? 0)
                }
            }
            if(item.0.stringOptional=="s1_longitude"){
               if (item.1.doubleOptional != nil){
                  self.s1_lon = (item.self.1.doubleOptional ?? 0)
               }
           }
            if(item.0.stringOptional=="s_act"){
                        if (item.1.stringOptional != nil){
                           self.s_act = (item.self.1.stringOptional ?? "s_act")
                        }
                    }
        }
            print("______________s_act payload:\(self.s_act ?? "s_act_null")")
            print("coordinate of client-s1:\(self.s1_lat),\(self.s1_lon)")

        }// close listener
        
          pubnub.add(listener)
          pubnub.subscribe(to: channels,
                        withPresence: true)
             
    } //  end of startListeningToChannel()
    
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
        rideState.text = "Stopped"
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
        let userUUID = pubnub.configuration.uuid
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
            
            self.pubnub.publish(channel: self.channels[0], message: userPayload(name: userUUID, currentCredit: currentCredit, userActivation: false, u_act_from_API: "u_act_0", forceStop: false, startRiding: globalStart, stopRiding: stop, description: nil)) { result in
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
            
            self.pubnub.publish(channel: self.channels[0], message: userPayload(name: userUUID, currentCredit: currentCredit, userActivation: false, u_act_from_API: "u_act_0", forceStop: false, startRiding: globalStart, stopRiding: stop, description: nil)) { result in
            print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
            }
        }
        else{
            startListeningToChannel()
            if(self.s_act == "s_act_0"){
                displayAlert(title: "Scooter Disabled", message: "Scooter is not in service!\nDo not ride this scooter!")
            stop = stopRidingTime()
            isRiding = false
            rideState.text = "Offline"
            self.pubnub.publish(channel: self.channels[0], message: userPayload(name: userUUID, currentCredit: currentCredit, userActivation: false, u_act_from_API: "u_act_0", forceStop: false, startRiding: globalStart, stopRiding: stop, description: nil)) { result in
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
                    
                
                    self.pubnub.publish(channel: self.channels[0], message:userPayload(name: userUUID, currentCredit: currentCredit, userActivation: true, u_act_from_API: "u_act_1", forceStop: false, startRiding: start, stopRiding: nil, description: nil)) {
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
        print("Relocating user to \(String(describing: currentLocation))\n")
        mapView.centerToLocation(currentLocation)

    }

    @IBAction func sliderMoved(_ slider: UISlider){
        let roundedValue = slider.value.rounded()
        currentCredit = Double(roundedValue)
        currentCreditLabel.text = String(currentCredit)
    }
    
    @objc func keepOnListeningToHandshake(){
            handshakeListenerTicker += 1
            waitForAckLabel.text = String(handshakeListenerTicker)
//            print("Count:\(handshakeListenerTicker)")
            listener.didReceiveMessage = { message in
            print("[Payload]: \(message.payload)")
            let hs = message.payload

            for item in hs{
//                print("found item:\(item.0)")
                if(item.0.stringOptional=="handshakeAck"){
                   self.handshakeAck = item.1.boolOptional ?? false
                }
//                print("current HS:\(self.handshakeAck)")
            }

            print("[Handshake from]: \(message.publisher ?? "defaultUUID")")
                self.scooterUUID = message.publisher!
            }
        
        if(self.handshakeAck == true){
            let msg = "Enjoy your ride!"
            displayAlert(title:"Validation Completed!",message:msg)
            handshakeListenerCounter?.invalidate()
            hslistenerFlag = false
            checkForHandshake()
        }
                
    }
    // CLLocationCoordinate2D
    func getDirections(loc1: CLLocationCoordinate2D, loc2: CLLocationCoordinate2D) {
    let userUUID = pubnub.configuration.uuid
       let source = MKMapItem(placemark: MKPlacemark(coordinate: loc1))
       source.name = userUUID
       let destination = MKMapItem(placemark: MKPlacemark(coordinate: loc2))
       destination.name = "client-s1"
       MKMapItem.openMaps(with: [source, destination], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    func checkForHandshake(){
        
        if(code == "5347"){
            print("user location:\(self.userLat) , \(self.userLon)")
            print("client location:\(self.s1_lat) , \(self.s1_lon)")

            let user_location = CLLocation(latitude:self.userLat, longitude:self.userLon)
            let client_location = CLLocation(latitude:self.s1_lat, longitude:self.s1_lon)
            
            let user_marker = CLLocationCoordinate2D(latitude: CLLocationDegrees(exactly: self.userLat)!, longitude: CLLocationDegrees(exactly: self.userLon)!)
            let client_marker = CLLocationCoordinate2D(latitude: CLLocationDegrees(exactly: self.s1_lat)!, longitude: CLLocationDegrees(exactly: self.s1_lon)!)
            let distance = user_location.distance(from: client_location)
            self.distanceToClientLabel.text = String(distance.rounded())+" m"
            print("you are \(distance.rounded()) meter away from the client")
            
            if(distance >= 10.0){
                self.getDirections(loc1: user_marker, loc2: client_marker)
//                self.rideNowButton.isHidden = false

                let msg = "You are too far from the scooter\n\nYou must be within 2 meter away from scooter to unlock"
                displayAlert(title:"Cannot Unlock!",message:msg)
            }
            else{
                
                let msg = "Waiting for scooter response."
                displayAlert(title:"Unlock Successful!",message:msg)
                self.rideNowButton.isHidden = false

                // allow user to unlock scooter if distance less than 2 meter
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
            
        }
       else{
           self.rideNowButton.isHidden = true
           self.slider.isHidden = true
       }
    }
    
    
    func promptForUnlockCode() {
        
        if(currentCredit <= unlockCost){
            displayAlert(title: "Insufficient Credit!", message: "Please top up your credit!")
            
        }
        else{
            let userUUID = pubnub.configuration.uuid
            let input = UIAlertController(title: "Enter Unlock Code", message: "Unlock Code is the 4-digit number found on scooter dashboard.", preferredStyle: .alert)
            input.addTextField()
           
            let submitAction = UIAlertAction(title: "Unlock Now", style: .default) { [unowned input] _ in
               self.code = input.textFields![0].text!
                // do something interesting with "answer" here
              
              
               print("Unlock code entered:\(self.code) + handshake:\(self.handshakeAck)")
            self.pubnub.publish(channel: self.channels[0], message: gimmeAck(name: userUUID, unlockCodeGiven: self.code, askingForAck: true)) { result in
                     print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
                     }
               self.checkForHandshake()
               //Unlock code entered:<_UIAlertControllerTextField: 0x7fd8f2864400; frame = (7 6.5; 225 17.5); text = '1234'; opaque = NO; gestureRecognizers = <NSArray: 0x60000088e130>; layer = <CALayer: 0x600000748440>>
           }
            

           input.addAction(submitAction)
           present(input, animated: true)
         
            
        }
       
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

//extension GeolocationService: CLLocationManagerDelegate {
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let location = locations.last {
//            let geoLocation = GeoLocation(userLatitude: location.coordinate.latitude, userLongitude: location.coordinate.longitude)
//            delegate.didFetchCurrentLocation(geoLocation)
//        }
//    }
//
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        delegate.fetchCurrentLocationFailed(error: error)
//    }
//}
