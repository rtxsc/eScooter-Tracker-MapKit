//
//  payload.swift
//  eScooter Tracker MapKit
//
//  Created by Yazid on 18/05/2020.
//  Copyright © 2020 UiTM Kampus Samarahan Cawangan Sarawak. All rights reserved.
//

import Foundation

struct User:Codable
{
    var firstName:String
    var lastName:String
    var country:String

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case country
    }
}
