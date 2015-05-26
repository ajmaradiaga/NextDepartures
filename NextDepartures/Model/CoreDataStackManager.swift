//
//  CoreDataStackManager.swift
//  VirtualTourist
//
//  Created by Antonio Maradiaga on 9/04/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import CoreData

/**
* The CoreDataStackManager contains the code that was previously living in the
* AppDelegate in Lesson 3. Apple puts the code in the AppDelegate in many of their
* Xcode templates. But they put it in a convenience class like this in sample code
* like the "Earthquakes" project.a
*
*/

private let SQLITE_FILE_NAME = "TransportModel.sqlite"
private let SQLITE_FILE_NAME_SCRATCH = "TransportModel_Scratch.sqlite"

class CoreDataStackManager {
    
    
    // MARK: - Shared Instance
    class func sharedInstance() -> CoreDataStackManager {
        struct Static {
            static let instance = CoreDataStackManager()
        }
        
        return Static.instance
    }
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
        }()
    
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        let modelURL = NSBundle.mainBundle().URLForResource("TransportModel", withExtension: "momd")
        let mom = NSManagedObjectModel(contentsOfURL: modelURL!)
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom!)
        
        let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
        
        var error: NSError? = nil
        
        var store = psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error)
        if (store == nil) {
            println("Failed to load store")
        }
        
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = psc
        
        return managedObjectContext
        }()
    
    lazy var scratchManagedObjectContext: NSManagedObjectContext? = {
        let modelURL = NSBundle.mainBundle().URLForResource("TransportModel", withExtension: "momd")
        let mom = NSManagedObjectModel(contentsOfURL: modelURL!)
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom!)
        
        let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME_SCRATCH)
        
        var error: NSError? = nil
        
        var store = psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error)
        if (store == nil) {
            println("Failed to load store")
        }
        
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = psc
        
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        
        if let context = self.managedObjectContext {
            
            var error: NSError? = nil
            
            if context.hasChanges && !context.save(&error) {
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
}