//
//  UdacityConstants.swift
//  OnTheMap
//
//  Created by Antonio Maradiaga on 26/03/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit

extension PTVClient {

    // MARK: - Constants
    struct Constants {
        static let BaseURL : String = "http://timetableapi.ptv.vic.gov.au"
        static let Version : String = "v2"
        static let DeveloperID : String = "1000416"
        static let SecurityKey : String = "36f64d5c-e6f9-11e4-9dfa-061817890ad2"
        static let DataFormat : String = "json"
        static let NoJSONCallbank = "1"
        static let BoundingBoxHalfWidth = 1.0
        static let BoundingBoxHalfHeight = 1.0
    }
    
    enum TransportMode : Int32 {
        case Train = 0,
        Tram = 1,
        Bus = 2,
        VLine = 3,
        NightRider = 4
        
        static func transportModeFromString(value : String) -> TransportMode {
            switch value {
                case "tram":
                    return .Tram
                case "bus":
                    return .Bus
                case "train":
                    return .Train
                default:
                    return .Tram
            }
        }
        
        static func imageNameForTransportType(value : String) -> String {
            switch value {
            case "tram":
                return "tram"
            case "bus":
                return "bus"
            case "nightrider":
                return "bus"
            case "train":
                return "train"
            case "vline":
                return "train"
            default:
                return "tram"
            }
        }
        
        static func colorForTransportType(value : String) -> UIColor {
            switch value {
            case "tram":
                return UIColor(red: 48/255, green: 185/255, blue: 114/255, alpha: 1)
            case "bus":
                return UIColor(red: 253/255, green: 160/255, blue: 34/255, alpha: 1)
            case "nightrider":
                return UIColor(red: 253/255, green: 160/255, blue: 34/255, alpha: 1)
            case "train":
                return UIColor(red: 20/255, green: 155/255, blue: 234/255, alpha: 1)
            case "vline":
                return UIColor.brownColor()
            default:
                return UIColor.greenColor()
            }
        }
    }
    
    struct Methods{
        static let NearMe: String = "nearme/latitude/%f/longitude/%f"
        static let HealthCheck: String = "healthcheck"
        static let NextDeparturesForStop: String = "mode/%i/stop/%i/departures/by-destination/limit/%i"
        static let StopsForLine: String = "mode/%i/line/%i/stops-for-line"
        static let StoppingPattern: String = "mode/%i/run/%i/stop/%i/stopping-pattern"
    }

}