//
//  TransportManager.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 9/05/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class TransportManager: NSObject, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate {
    
    typealias CompletionHandler = (result: AnyObject?, error: NSError?) -> Void
    
    var initialised : Bool = false
    
    var isRefreshingData : Bool = false
    var timeTableStops : NSArray = [NSNumber]()
    
    var locationManager = CLLocationManager()
    var centerLocation : CLLocation?
    var userCurrentLocation : CLLocation?
    
    //Keep track of the Last locations for the last refresh of data
    var lastLocationFetched : CLLocation?
    var lastUserCurrentLocationFetched : CLLocation?
    var lastTimeFetched : NSDate?
    
    var fetchForFirstTime : Bool = false
    
    var sortedTimeTable : [Timetable]?
    var trackingStops : [TrackingStop] = [TrackingStop]()
    
    var scheduledTimer = NSTimer()
    
    var requestFetchMode : TimetableFetchMode = .Default
    
    enum TimetableFetchMode : Int32 {
        case Default = 0,
        UniqueStop = 1,
        Watch = 2
    }
    
    struct Constants {
        static let MinimumDistanceFromStop : Double = 200
    }
    
    class func sharedInstance() -> TransportManager {
        struct Singleton {
            static var sharedInstance = TransportManager()
        }
        if !Singleton.sharedInstance.initialised {
            Singleton.sharedInstance.initialised = true
            Singleton.sharedInstance.setupTransportManager()
        }
        
        return Singleton.sharedInstance
    }
    
    func setupTransportManager() {
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        trackingStopFetchedResultsController.delegate = self
        trackingStopFetchedResultsController.performFetch(nil)
        
        trackingServiceFetchedResultsController.delegate = self
        trackingServiceFetchedResultsController.performFetch(nil)
        
        self.scheduledTimer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: Selector("checkTrackingService:"), userInfo: nil, repeats: true)
        
        if(CLLocationManager.locationServicesEnabled()) {
            if (IS_OS_8_OR_LATER) {
                if CLLocationManager.authorizationStatus() == .NotDetermined {
                    self.locationManager.requestAlwaysAuthorization()
                }
            } else {
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    func reinitialiseLocationManager() {
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else if status == CLAuthorizationStatus.NotDetermined && IS_OS_8_OR_LATER {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        
        if self.centerLocation == nil {
            self.centerLocation = location
        }
        
        self.userCurrentLocation = location
        
        if self.trackingStopFetchedResultsController.fetchedObjects!.count > 0 {
            
            for index in 1...self.trackingStopFetchedResultsController.fetchedObjects!.count {
                
                var item = self.trackingStopFetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: index - 1, inSection: 0)) as! TrackingStop
                
                if item.enabled == true {
                    var distance = location.distanceFromLocation(item.stop.location)
                    
                    var formattedDistance = Helper.formatDistanceToString(distance)
                    
                    if distance < item.trackingDistance {
                        //Raise alert and remove from Notifications
                        Helper.raiseNotification("You are \(formattedDistance) away from \(item.stop.stopName)", withTitle:"Get Ready", completionHandler: { () -> Void in
                            println("Notification raised")
                            item.enabled = false
                        })
                        
                    }
                }
            }
            
        }
    }
    
    lazy var stopFetchRequest : NSFetchRequest = {
        let fetchRequest = NSFetchRequest(entityName: "Stops")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Stops.Keys.StopId, ascending: true)]
        
        return fetchRequest
        }()
    
    lazy var stopFetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = self.stopFetchRequest
        
        //println("Objects in Stops: \(self.sharedContext.countForFetchRequest(fetchRequest, error:nil))")
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    lazy var trackingStopFetchRequest : NSFetchRequest = {
        let fetchRequest = NSFetchRequest(entityName: "TrackingStop")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "\(TrackingStop.Keys.Stop).\(Stops.Keys.StopId)", ascending: true)]
        
        return fetchRequest
        }()
    
    lazy var trackingStopFetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = self.trackingStopFetchRequest
        
        //println("Objects in Tracking Stop: \(self.sharedContext.countForFetchRequest(fetchRequest, error:nil))")
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    lazy var trackingServiceFetchRequest : NSFetchRequest = {
        let fetchRequest = NSFetchRequest(entityName: "TrackingService")
        
        fetchRequest.predicate = NSPredicate(format: "\(TrackingService.Keys.Enabled) == true")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "\(TrackingService.Keys.Timetable).\(Timetable.Keys.RunId)", ascending: true)]
        
        return fetchRequest
        }()
    
    lazy var trackingServiceFetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = self.trackingServiceFetchRequest
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    func refreshTimeTableFetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: "Timetable")
        
        fetchRequest.fetchLimit = 50
        
        if requestFetchMode == .Default {
            if timeTableStops.count == 0 {
                fetchRequest.predicate = NSPredicate(format: "\(Timetable.Keys.TimeUTC) > %@", NSDate())
            } else {
                fetchRequest.predicate = NSPredicate(format: "( \(Timetable.Keys.TimeUTC ) > %@ ) AND ( \(Timetable.Keys.Stop).\(Stops.Keys.StopId) IN %@ )", NSDate(), timeTableStops)
            }
        } else if requestFetchMode == .UniqueStop || requestFetchMode == .Watch {
            fetchRequest.predicate = NSPredicate(format: "( \(Timetable.Keys.TimeUTC ) > %@ ) AND ( \(Timetable.Keys.Stop).\(Stops.Keys.StopId) IN %@ )", NSDate(), timeTableStops)
        }
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Timetable.Keys.TimeUTC, ascending: true)]
        
        return fetchRequest
    }
    
    
    //MARK: NSFetchedResults Delegate
    lazy var timeTableFetchedResultsController: NSFetchedResultsController = {
        return self.refreshTimeTableFetchedResultsController()
        
        }()
    
    func refreshTimeTableFetchedResultsController() -> NSFetchedResultsController {
        let fetchRequest = self.refreshTimeTableFetchRequest()
        
        var error: NSError? = nil
        
        //println("Objects in Timetable: \(self.sharedContext.countForFetchRequest(fetchRequest, error:&error))")
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }
    
    func fetchDataForStop(stop:Stops, completionHandler: CompletionHandler) {
        fetchDataForLocation(TimetableFetchMode.UniqueStop, location: stop.location, andStops: [NSNumber(int: stop.stopId)], completionHandler: completionHandler)
    }
    
    func fetchDataForLocation(requestMode: TimetableFetchMode,var location:CLLocation?, andStops stops:NSArray?, completionHandler: CompletionHandler) {
        
        self.requestFetchMode = requestMode
        
        if stops != nil {
            self.timeTableStops = stops!
        }
        
        if isRefreshingData == false {
            isRefreshingData = true
            
            //Set Last Location variables
            lastLocationFetched = location
            lastUserCurrentLocationFetched = userCurrentLocation
            lastTimeFetched = NSDate()
            
            if location != nil {
                self.centerLocation = location
            } else {
                location = self.centerLocation
            }
            PTVClient.sharedInstance().stopsNearby(location!, completionHandler: { (result, error) -> Void in
                
                var error:NSError?
                
                var stopsRetrieved = [Stops]()
                
                if result != nil {
                    stopsRetrieved = result as! [Stops]
                }
                
                //Set TimetableStops when Fetch mode is Watch, this is to handle the scenario when the User Location is different than the location from the map center
                if self.requestFetchMode == .Watch && stopsRetrieved.count > 0 {
                    self.timeTableStops = Stops.stopIdsInArray(stopsRetrieved)
                    println("Retrieve stops - Watch")
                }
                
                //Saving the value of Delegate
                var auxDelegate = self.timeTableFetchedResultsController.delegate
                
                self.timeTableFetchedResultsController = self.refreshTimeTableFetchedResultsController()
                
                self.timeTableFetchedResultsController.delegate = auxDelegate
                
                self.timeTableFetchedResultsController.performFetch(&error)
                
                self.isRefreshingData = false
                
                if error == nil {
                    completionHandler(result: result, error: nil)
                } else {
                    println("Error - FetchDataForLocation: \(error?.localizedDescription)")
                    completionHandler(result: nil, error: error)
                }
            })
        }
    }
    
    
    
    func shouldUpdateData(requestMode: TimetableFetchMode) -> Bool {
        
        if lastLocationFetched == nil || lastUserCurrentLocationFetched == nil || lastTimeFetched == nil {
            return true
        }
        
        //Check if the transport manager is currently refreshing data
        if isRefreshingData == true {
            return false
        }
        
        var distanceFromLastLocation = lastUserCurrentLocationFetched?.distanceFromLocation(userCurrentLocation)
        
        var timeFromLastFetched = NSDate().timeIntervalSinceDate(lastTimeFetched!)
        
        if requestMode == .Watch && (timeFromLastFetched > 60 || distanceFromLastLocation > 100) {
            return true
        }
        
        return false
    }
    
    func addTrackingService(timeTable: Timetable, withSeconds seconds: Int32) -> TrackingService {
        let trackingServiceInformation: [String: AnyObject?] = [
            TrackingService.Keys.Timetable : timeTable,
            TrackingService.Keys.TimeInSecs : NSNumber(int: seconds)
        ]
        
        var newTrackingSvc = TrackingService.retrieveTrackingService(trackingServiceInformation, context: sharedContext)
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        trackingServiceFetchedResultsController.performFetch(nil)
        
        return newTrackingSvc
    }
    
    func addTrackingStop(stop: Stops, withDistance distance: Double) -> TrackingStop {
        let trackingStopInformation: [String: AnyObject?] = [
            TrackingStop.Keys.Stop : stop,
            TrackingStop.Keys.TrackingDistance : distance,
            TrackingStop.Keys.Enabled : true
        ]
        
        var newTrackingStop = TrackingStop.retrieveTrackingStop(trackingStopInformation, context: sharedContext)
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        trackingStopFetchedResultsController.performFetch(nil)
        
        return newTrackingStop
    }
    
    func checkTrackingService(timer:NSTimer) {
        if self.trackingServiceFetchedResultsController.fetchedObjects!.count > 0 {
            for index in 1...self.trackingServiceFetchedResultsController.fetchedObjects!.count {
                
                var item = self.trackingServiceFetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: index - 1, inSection: 0)) as! TrackingService
                
                if Int32(item.timeTable.timeFromNow()) < item.timeInSecs {
                    item.enabled = false
                    println("\(item.timeTable.timeFromNow()) - \(item.timeInSecs)")
                    Helper.raiseNotification("You should be @ \(item.timeTable.stop.stopName) in < \(item.timeInSecs / 60) mins", withTitle: "Get Ready", completionHandler: { () -> Void in
                    })
                }
            }
            
            CoreDataStackManager.sharedInstance().saveContext()
            trackingServiceFetchedResultsController.performFetch(nil)
        }
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
}
    