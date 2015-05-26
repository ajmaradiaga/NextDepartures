//
//  TrackingStop.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 19/05/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import CoreData

@objc(TrackingStop)

class TrackingStop : NSManagedObject, Printable {
    
    struct Keys {
        static let Stop = "stop"
        static let TrackingDistance = "trackingDistance"
        static let Enabled = "enabled"
    }
    
    @NSManaged var stop : Stops
    @NSManaged var trackingDistance : Double
    @NSManaged var enabled : Bool
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject?], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("TrackingStop", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        self.trackingDistance = (dictionary[Keys.TrackingDistance] as! NSNumber).doubleValue
        self.enabled = (dictionary[Keys.Enabled] as! Bool)
        self.stop = dictionary[Keys.Stop] as! Stops
    }
    
    class func retrieveTrackingStop(dictionary: [String : AnyObject?], context: NSManagedObjectContext) -> TrackingStop {
        
        let fetchRequest = NSFetchRequest(entityName: "TrackingStop")
        var error : NSError?
        
        fetchRequest.predicate = NSPredicate(format: "\(Keys.TrackingDistance) == %f and \(Keys.Stop).\(Stops.Keys.StopId) == %i", (dictionary[Keys.TrackingDistance] as! NSNumber).doubleValue,(dictionary[Keys.Stop] as! Stops).stopId)
        
        //println(context.countForFetchRequest(fetchRequest, error: &error))
        
        if context.countForFetchRequest(fetchRequest, error: &error) > 0 {
            return context.executeFetchRequest(fetchRequest, error: &error)!.last as! TrackingStop
        } else {
            return TrackingStop(dictionary: dictionary, context: context)
        }
    }
    
    override var description: String {
        return "\(stop.stopName)  \(Helper.formatDistanceToString(trackingDistance))"
    }
}