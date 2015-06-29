//
//  Stops.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 25/04/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Stops)

class Stops: NSManagedObject {
    
    struct Keys {
        static let Suburb = "suburb"
        static let TransportType = "transportType"
        static let LocationName = "locationName"
        static let StopId = "stopId"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Timetable = "timetable"
        static let Line = "line"
        static let ServicesList = "servicesList"
    }
    
    @NSManaged var suburb: String
    @NSManaged var transportType: String
    @NSManaged var locationName: String
    @NSManaged var stopId: Int32
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var timetable: NSSet
    @NSManaged var line: Line
    @NSManaged var servicesList: String?
    
    
    var location: CLLocation? {
        get {
            return CLLocation(latitude: self.latitude, longitude: self.longitude)
        }
        set (value) {
            self.latitude = value!.coordinate.latitude
            self.longitude = value!.coordinate.longitude
        }
    }
    
    var patternType : StopPatternType = .Past
    
    enum StopPatternType : Int32 {
        case Past = 0,
        Present = 1,
        Future = 2
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject?], context: NSManagedObjectContext) {
            let entity =  NSEntityDescription.entityForName("Stops", inManagedObjectContext: context)!
            
            super.init(entity: entity,insertIntoManagedObjectContext: context)
            
            self.suburb = dictionary[Keys.Suburb] as! String
            self.transportType = dictionary[Keys.TransportType] as! String
            self.locationName = dictionary[Keys.LocationName] as! String
            self.stopId = (dictionary[Keys.StopId] as! NSNumber).intValue
            self.latitude = (dictionary[Keys.Latitude] as! NSNumber).doubleValue
            self.longitude = (dictionary[Keys.Longitude] as! NSNumber).doubleValue
    }
    
    class func retrieveStop(dictionary: [String : AnyObject?], context: NSManagedObjectContext) -> Stops {

        let fetchRequest = NSFetchRequest(entityName: "Stops")
        var error : NSError?
        
        fetchRequest.predicate = NSPredicate(format: "\(Keys.StopId) == %i and \(Keys.TransportType) == %@", (dictionary[Stops.Keys.StopId] as! NSNumber).intValue, dictionary[Stops.Keys.TransportType] as! String)
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "\(Keys.StopId)", ascending: true)]
        
        var elements : [AnyObject]?
        elements = context.executeFetchRequest(fetchRequest, error: &error)
        if elements != nil {
            if elements!.count > 0 {
                var stop = elements!.last as! Stops
                
                return stop
            }
        }
        return Stops(dictionary: dictionary, context: context)
    }
    
    class func stopIdsInArray(stopsArray : NSArray) -> NSArray {
        var stopIdArray = NSMutableArray()
        
        for element in stopsArray {
            var stopId = NSNumber(int:(element as! Stops).stopId)
            if !stopIdArray.containsObject(stopId) {
                stopIdArray.addObject(stopId)
            }
        }
        
        //println(stopIdArray)
        
        return stopIdArray
    }
    
    var stopName : String {
        get {
            return "\(stopId) - \(locationName)"
        }
    }
}
