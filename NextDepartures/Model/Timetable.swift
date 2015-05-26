//
//  Timetable.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 25/04/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import CoreData
import NextDeparturesFramework

@objc(Timetable)

class Timetable: NSManagedObject, Printable {

    struct Keys {
        static let RunId = "runId"
        static let DestinationId = "destinationId"
        static let DestinationName = "destinationName"
        static let TransportType = "transportType"
        static let TimeUTC = "timeUTC"
        static let Line = "line"
        static let LineDirection = "lineDirection"
        static let Stop = "stop"
        static let StopId = "stopId"
    }
    
    @NSManaged var timeUTC: NSDate
    @NSManaged var transportType: String
    @NSManaged var runId: Int32
    @NSManaged var destinationId: Int32
    @NSManaged var destinationName: String
    @NSManaged var line: Line
    @NSManaged var lineDirection : Direction
    @NSManaged var stop: Stops
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject?], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Timetable", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        self.runId = (dictionary[Keys.RunId] as! NSNumber).intValue
        self.destinationId = (dictionary[Keys.DestinationId] as! NSNumber).intValue
        self.destinationName = dictionary[Keys.DestinationName] as! String
        self.transportType = dictionary[Keys.TransportType] as! String
        self.lineDirection = dictionary[Keys.LineDirection] as! Direction
        
        self.setTimeUTCFromStringValue(dictionary[Keys.TimeUTC] as! String)
    }
    
    class func retrieveTimetable(dictionary: [String : AnyObject?], context: NSManagedObjectContext) -> Timetable {
        
        let fetchRequest = NSFetchRequest(entityName: "Timetable")
        var error : NSError?
        
        fetchRequest.predicate = NSPredicate(format: "\(Keys.RunId) == %i and \(Keys.TransportType) == %@ and \(Keys.Stop).\(Stops.Keys.StopId) == %i", (dictionary[Keys.RunId] as! NSNumber).intValue, dictionary[Keys.TransportType] as! String, (dictionary[Keys.StopId] as! NSNumber).intValue)
        
        //println(context.countForFetchRequest(fetchRequest, error: &error))
        
        if context.countForFetchRequest(fetchRequest, error: &error) > 0 {
            var aux = context.executeFetchRequest(fetchRequest, error: &error)!.last as! Timetable
            aux.setTimeUTCFromStringValue(dictionary[Keys.TimeUTC] as! String)
            
            return aux
        } else {
            return Timetable(dictionary: dictionary, context: context)
        }
    }
    
    func setTimeUTCFromStringValue(value : String) {
        var timeUTC = value.stringByReplacingOccurrencesOfString("T", withString: " ")
        if let dateUTC = Helper.dateFormatter.dateFromString(timeUTC) {
            self.timeUTC = dateUTC
        }
    }
    
    func displayTimeFromNow() -> String {
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
    
    func timeFromNow() -> NSTimeInterval {
        return self.timeUTC.timeIntervalSinceDate(NSDate())
    }
    
    override var description: String {
        return String(runId) + " - " + String(line.lineNumber) + " - " + lineDirection.directionName + " - " + displayTimeFromNow()
    }
    
    /*
    static let RunId = "runId"
    static let DestinationId = "destinationId"
    static let DestinationName = "destinationName"
    static let TransportType = "transportType"
    static let TimeUTC = "timeUTC"
    static let Line = "line"
    static let LineDirection = "lineDirection"
    static let Stop = "stop"
    static let StopId = "stopId"
*/
    
    func convertToTimetableCommon() -> TimetableCommon {
        return TimetableCommon(runId: self.runId, timeUTC: self.timeUTC, transportType: self.transportType, destinationId: self.destinationId, destinationName: self.destinationName, stopId: self.stop.stopId, stopName: self.stop.stopName, stopLatitude: self.stop.latitude, stopLongitude: self.stop.longitude, stopLocationName: self.stop.locationName, lineNumber: self.line.lineNumber, lineDirectionName: self.lineDirection.directionName)
    }
    
}
