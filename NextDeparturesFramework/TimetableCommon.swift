//
//  TimetableCommon.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 25/05/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit

public class TimetableCommon: NSObject, NSCoding {
   
    public struct Keys {
        static let RunId = "runId"
        static let DestinationId = "destinationId"
        static let DestinationName = "destinationName"
        static let TransportType = "transportType"
        static let TimeUTC = "timeUTC"
        static let Line = "line"
        static let LineDirection = "lineDirection"
        static let StopId = "stopId"
        static let StopName = "stopName"
        static let StopLongitude = "stopLongitude"
        static let StopLatitude = "stopLatitude"
        static let StopLocationName = "stopLocationName"
        static let LineNumber = "lineNumber"
        static let LineDirectionName = "lineDirectionName"
    }
    
    public var timeUTC: NSDate = NSDate()
    public var transportType: String = ""
    public var runId: Int32 = 0
    public var destinationId: Int32 = 0
    public var destinationName: String = ""
    public var lineNumber: String = ""
    public var lineDirectionName : String = ""
    public var stopLatitude : Double = 0.0
    public var stopLongitude : Double = 0.0
    public var stopLocationName : String = ""
    public var stopId: Int32 = 0
    public var stopName: String = ""
    
    /*
    esponse["MainTextLabel"] = item.line.lineNumber + " - " + item.lineDirection.directionName
    response["SubTextLabel"] = item.displayTimeFromNow() //String(item.stop.stopId) + " - " + item.stop.locationName
    response["Latitude"] = item.stop.latitude
    response["Longitude"] = item.stop.longitude
    */
    
    public init(runId _runId: Int32, timeUTC _timeUTC:NSDate, transportType _transportType: String, destinationId _destinationId: Int32, destinationName _destinationName: String, stopId _stopId: Int32, stopName _stopName: String, stopLatitude _stopLatitude: Double, stopLongitude _stopLongitude: Double, stopLocationName _stopLocationName: String, lineNumber _lineNumber: String, lineDirectionName _lineDirectionName: String) {
        self.runId = _runId
        self.timeUTC = _timeUTC
        self.transportType = _transportType
        self.destinationId = _destinationId
        self.destinationName = _destinationName
        self.stopId = _stopId
        self.stopName = _stopName
        self.stopLatitude = _stopLatitude
        self.stopLongitude = _stopLongitude
        self.lineNumber = _lineNumber
        self.lineDirectionName = _lineDirectionName
        self.stopLocationName = _stopLocationName
    }
    
    public func displayTimeFromNow() -> String {
        var timeSince = self.timeUTC.timeIntervalSinceDate(NSDate())
        var displayTime = ""
        
        var timeValue : Double = 0
        var timeDescription : String = "secs"
        
        if timeSince < 60 && timeSince > 0 {
            timeValue = timeSince
        } else if timeSince > 60 && timeSince < 3600 {
            timeValue = timeSince / 60
            timeDescription = "mins"
        } else if timeSince > 3600 {
            timeValue = timeSince / 3600
            timeDescription = "hours"
        } else {
            displayTime = "0"
        }
        
        displayTime = String(format: "%0.0f %@", timeValue, timeDescription)
        
        return displayTime
    }
    
    public required init(coder aDecoder: NSCoder) {
        //super.init()
        
        self.runId = aDecoder.decodeInt32ForKey(Keys.RunId)
        self.destinationId = aDecoder.decodeInt32ForKey(Keys.DestinationId)
        self.destinationName = aDecoder.decodeObjectForKey(Keys.DestinationName) as! String
        self.transportType = aDecoder.decodeObjectForKey(Keys.TransportType) as! String
        self.timeUTC = aDecoder.decodeObjectForKey(Keys.TimeUTC) as! NSDate
        self.stopId = aDecoder.decodeInt32ForKey(Keys.StopId)
        self.stopName = aDecoder.decodeObjectForKey(Keys.StopName) as! String
        self.stopLatitude = aDecoder.decodeDoubleForKey(Keys.StopLatitude)
self.stopLongitude = aDecoder.decodeDoubleForKey(Keys.StopLongitude)
                self.stopLocationName = aDecoder.decodeObjectForKey(Keys.StopLocationName) as! String
                self.lineNumber = aDecoder.decodeObjectForKey(Keys.LineNumber) as! String
                self.lineDirectionName = aDecoder.decodeObjectForKey(Keys.LineDirectionName) as! String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInt32(runId, forKey: Keys.RunId)
        aCoder.encodeInt32(destinationId, forKey: Keys.DestinationId)
        aCoder.encodeObject(destinationName, forKey: Keys.DestinationName)
        aCoder.encodeObject(transportType, forKey: Keys.TransportType)
        aCoder.encodeObject(timeUTC, forKey:Keys.TimeUTC)
        aCoder.encodeInt32(stopId, forKey: Keys.StopId)
        aCoder.encodeObject(stopName, forKey: Keys.StopName)
        aCoder.encodeDouble(stopLatitude, forKey: Keys.StopLatitude)
        aCoder.encodeDouble(stopLongitude, forKey: Keys.StopLongitude)
        aCoder.encodeObject(stopLocationName, forKey: Keys.StopLocationName)
        aCoder.encodeObject(lineNumber, forKey: Keys.LineNumber)
        aCoder.encodeObject(lineDirectionName, forKey: Keys.LineDirectionName)
    }
    
}
