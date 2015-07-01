//
//  DataExchange.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 26/05/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation

public class DataExchange: NSObject {
    
    public struct Keys {
        public static let Request = "Request"
        public static let Response = "Response"
        public static let TimetableData = "TimetableData"
        public static let Error = "Error"
        public static let UserLocationLatitude = "UserLocationLatitude"
        public static let UserLocationLongitude = "UserLocationLongitude"
    }

}