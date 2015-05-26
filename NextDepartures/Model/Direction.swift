//
//  Line.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 25/04/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import CoreData

@objc(Direction)

class Direction: NSManagedObject {
    
    struct Keys {
        static let DirectionId = "directionId"
        static let DirectionName = "directionName"
        static let LineDirectionId = "lineDirectionId"
        static let Line = "line"
    }
    
    @NSManaged var directionId: Int32
    @NSManaged var directionName: String
    @NSManaged var lineDirectionId: Int32
    @NSManaged var line: Line
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject?], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Direction", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        self.directionId = (dictionary[Keys.DirectionId] as! NSNumber).intValue
        self.directionName = dictionary[Keys.DirectionName] as! String
        self.lineDirectionId = (dictionary[Keys.LineDirectionId] as! NSNumber).intValue
        self.line = dictionary[Keys.Line] as! Line
        
    }
    
    class func retrieveDirection(dictionary: [String : AnyObject?], context: NSManagedObjectContext) -> Direction {
        
        let fetchRequest = NSFetchRequest(entityName: "Direction")
        var error : NSError?
        
        fetchRequest.predicate = NSPredicate(format: "\(Keys.DirectionId) == %i", (dictionary[Keys.DirectionId] as! NSNumber).intValue)
        
        //println(context.countForFetchRequest(fetchRequest, error: &error))
        
        if context.countForFetchRequest(fetchRequest, error: &error) > 0 {
            return context.executeFetchRequest(fetchRequest, error: &error)!.last as! Direction
        } else {
            return Direction(dictionary: dictionary, context: context)
        }
    }
    
}
