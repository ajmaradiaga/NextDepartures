//
//  Line.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 25/04/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import CoreData

@objc(Line)

class Line: NSManagedObject {

    struct Keys {
        static let LineId = "lineId"
        static let LineName = "lineName"
        static let LineNumber = "lineNumber"
        static let TransportType = "transportType"
    }
    
    @NSManaged var lineId: Int32
    @NSManaged var lineName: String
    @NSManaged var lineNumber: String
    @NSManaged var transportType: String
    @NSManaged var runs: NSSet
    @NSManaged var stops: NSSet

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject?], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Line", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        self.lineId = (dictionary[Keys.LineId] as! NSNumber).intValue
        self.lineName = dictionary[Keys.LineName] as! String
        self.lineNumber = dictionary[Keys.LineNumber] as! String
        self.transportType = dictionary[Keys.TransportType] as! String
        
    }
    
    class func retrieveLine(dictionary: [String : AnyObject?], context: NSManagedObjectContext) -> Line {
        
        let fetchRequest = NSFetchRequest(entityName: "Line")
        var error : NSError?
        
        fetchRequest.predicate = NSPredicate(format: "\(Keys.LineId) == %i and \(Keys.TransportType) == %@", (dictionary[Keys.LineId] as! NSNumber).intValue, dictionary[Keys.TransportType] as! String)
        
        //println(context.countForFetchRequest(fetchRequest, error: &error))
        
        if context.countForFetchRequest(fetchRequest, error: &error) > 0 {
            return context.executeFetchRequest(fetchRequest, error: &error)!.last as! Line
        } else {
            return Line(dictionary: dictionary, context: context)
        }
    }
    
}
