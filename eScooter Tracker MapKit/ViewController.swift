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

class ViewController: UIViewController {
    
    var pubnub: PubNub!
    let channels = ["Robotronix"]
    let listener = SubscriptionListener(queue: .main)

    var currentValue: Int = 50
    var targetValue: Int = 0
    var score = 0
    var round: Int = 0
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var target: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var roundLabel: UILabel!
    @IBOutlet weak var currentValueLabel: UILabel!
    
    fileprivate let locationManager:CLLocationManager = CLLocationManager()
       
       private let marker1 = MKPointAnnotation()
       private let marker2 = MKPointAnnotation()
       
       var lat = 1.583301
       var lon = 110.388393
       var shift_lat = 0.0 // running latitude
       var shift_lon = 0.0 // running longitude
       var radius = 0.001 // rotation radius
    
       var tick: Double! = 0.0
       var shift: Double! = 0.0
       var initialLocation: CLLocation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startListeningToChannel()
        // Do any additional setup after loading the view.
        let roundedValue = slider.value.rounded()
        currentValue = Int(roundedValue)
        self.restartGame()
        
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
        var labelmarker1 = PopUpLabel(
                          title: "sc1",
                          locationName: "\(self.marker1.coordinate.latitude), \(self.marker1.coordinate.longitude)",
                          discipline: "Vehicle",
                          coordinate: initialLocation.coordinate)

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

        // update new coordinates every 5 seconds
        newPosition1 = CLLocationCoordinate2D(latitude: self!.lat + self!.shift_lat, longitude: self!.lon + self!.shift_lon)
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
            print("[Message]: \(message)")
          }
          listener.didReceiveStatus = { status in
            switch status {
            case .success(let connection):
              if connection == .connected {
//                self.pubnub.publish(channel: self.channels[0], message: "Hello from iPhone SE 2020") { result in
//                  print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
//                }
                self.pubnub.publish(channel: self.channels[0], message: "Hello from iPhone SE 2020") { result in
                  switch result {
                  case .success(_):
//                    print("Handle successful Publish response: \(response)")
                    print(result.map {"Done my job at \($0.timetoken.timetokenDate)"})
                  case .failure(_):
//                    print("Handle response error: \(error.localizedDescription)")
                    print("Oh-ohh")
                  }
                }
                
              }
            case .failure(let error):
              print("Status Error: \(error.localizedDescription)")
            }
          }
          pubnub.add(listener)
          pubnub.subscribe(to: channels, withPresence: true)
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
    
    @IBAction func rideNow(){
        print("Unlocking scooter now...\n")
        self.pubnub.publish(channel: self.channels[0], message: "wallet=\(currentValue)") { result in
        print(result.map { "Publish Response at \($0.timetoken.timetokenDate)" })
        }
    }
    
    @IBAction func relocateUser(){
        print("Relocating user...\n")
        mapView.centerToLocation(initialLocation)

    }
    
    @IBAction func restartGame(){
        score = 0
        round = 0
        scoreLabel.text = String(score)
        startNewRound()
    }
    
    @IBAction func showAlert(){
        
        let difference = abs(currentValue - targetValue)
        let points = 100 - difference
        score += points
        scoreLabel.text = String(score)
        let message = "You scored: \(points) points"
        
        let title: String
        if difference == 0{
            title = "Perfect!"
        }
        else if difference < 5{
            title = "Almost there..."
        }
        else{
            title = "Not even close!"
        }
        
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        let action = UIAlertAction(title: "Return", style: .default, handler: nil)
        
//        alert.addAction(action)
//        present(alert,animated: true, completion: nil)
        
        startNewRound()
    }
    
    @IBAction func sliderMoved(_ slider: UISlider){
        let roundedValue = slider.value.rounded()
        currentValue = Int(roundedValue)
        currentValueLabel.text = String(currentValue)
    }
    
    func startNewRound() {
        round += 1
        targetValue = Int.random(in: 1...100)
        currentValue = 50
        slider.value = Float(currentValue)
        currentValueLabel.text = String(currentValue)
        roundLabel.text = String(round)
        updateTargetValue()
    }
    
    func updateTargetValue(){
        target.text = String(targetValue)
    }
}


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
    let identifier = "popuplabel"
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
      view.calloutOffset = CGPoint(x: -5, y: 5)
      view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    }
    return view
  }
}

private extension MKMapView {

  func centerToLocation(
    _ location: CLLocation,
    regionRadius: CLLocationDistance = 1000
  ) {
    let coordinateRegion = MKCoordinateRegion(
      center: location.coordinate,
      latitudinalMeters: regionRadius,
      longitudinalMeters: regionRadius)
    setRegion(coordinateRegion, animated: true)
  }
}
