//
//  TrackingService.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 23/06/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import CoreData

@objc(TrackingService)

class TrackingService: NSManagedObject {

    struct Keys {
        static let Timetable = "timeTable"
        static let TimeInSecs = "timeInSecs"
        static let Enabled = "enabled"
    }
    
    @NSManaged var timeInSecs: Int32
    @NSManaged var timeTable: Timetable
    @NSManaged var enabled : Bool

    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject?], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("TrackingService", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        self.timeInSecs = (dictionary[Keys.TimeInSecs] as! NSNumber).intValue
        self.timeTable = (dictionary[Keys.Timetable] as! Timetable)
        self.enabled = true
    }
    
    class func retrieveTrackingService(dictionary: [String : AnyObject?], context: NSManagedObjectContext) -> TrackingService {
        
        let fetchRequest = NSFetchRequest(entityName: "TrackingService")
        var error : NSError?
        
        fetchRequest.predicate = NSPredicate(format: "\(Keys.Timetable).\(Timetable.Keys.RunId) == %i", (dictionary[Keys.Timetable] as! Timetable).runId)
        
        if context.countForFetchRequest(fetchRequest, error: &error) > 0 {
            var trackingSvc = context.executeFetchRequest(fetchRequest, error: &error)!.last as! TrackingService
            trackingSvc.timeInSecs = (dictionary[Keys.TimeInSecs] as! NSNumber).intValue
            trackingSvc.enabled = true
            
            return trackingSvc
        } else {
            return TrackingService(dictionary: dictionary, context: context)
        }
    }
}
