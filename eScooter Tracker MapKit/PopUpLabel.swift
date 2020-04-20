//
//  PopUpLabel.swift
//  eScooter Tracker MapKit
//
//  Created by Yazid on 21/04/2020.
//  Copyright © 2020 UiTM Kampus Samarahan Cawangan Sarawak. All rights reserved.
//

import Foundation
import MapKit

class PopUpLabel: NSObject, MKAnnotation {
  let title: String?
  let locationName: String?
  let discipline: String?
  var coordinate: CLLocationCoordinate2D

  init(
    title: String?,
    locationName: String?,
    discipline: String?,
    coordinate: CLLocationCoordinate2D
  ) {
    self.title = title
    self.locationName = locationName
    self.discipline = discipline
    self.coordinate = coordinate

    super.init()
  }

  var subtitle: String? {
    return locationName
  }
}
