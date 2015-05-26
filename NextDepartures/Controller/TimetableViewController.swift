//
//  FirstViewController.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 19/04/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TimetableViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate {

    //Melbourne: -37.8140000, 144.9633200
    //Domain Interchange: -37.833786,144.971582
    
    struct MapKeys {
        static let Latitude = "LATITUDE"
        static let Longitude = "LONGITUDE"
        static let LatitudeDelta = "LATITUDE_DELTA"
        static let LongitudeDelta = "LONGITUDE_DELTA"
    }
    
    @IBOutlet weak var stopsMapView: MKMapView!
    @IBOutlet weak var nextDeparturesTable: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var locationManager = CLLocationManager()
    //var currentLocation : CLLocation?
    var selectedIndex : NSIndexPath?
    var tableRefreshControl = UIRefreshControl()
    
    var scheduledTimer = NSTimer()
    
    var isRefreshingData : Bool = false
    var fetchForFirstTime : Bool = false
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    var sharedTransport : TransportManager {
        return TransportManager.sharedInstance();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        NSNotificationCenter.defaultCenter().addObserverForName("timeTableComplete", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.handleTimeTableCompleteNotification(notification)
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("timeTablePartial", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.handleTimeTableCompleteNotification(notification)
        }
    
        //Timer that refresh the time value in the TableView
        self.scheduledTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: Selector("refreshTableViewCells:"), userInfo: nil, repeats: true)
        
        //Drag to refresh control of the TableView
        tableRefreshControl.addTarget(self, action:"fetchData:", forControlEvents: UIControlEvents.ValueChanged)
        nextDeparturesTable.addSubview(tableRefreshControl)
        
        //Setup Location Manager Delegate
        if(CLLocationManager.locationServicesEnabled()) {
            if IS_OS_8_OR_LATER {
                if CLLocationManager.authorizationStatus() == .NotDetermined {
                    locationManager.requestWhenInUseAuthorization()
                }
            } else {
                locationManager.startUpdatingLocation()
            }
        }
        
        //Refresh data that will be displayed in the Map and Table View
        sharedTransport.stopFetchedResultsController.delegate = self
        
        sharedTransport.stopFetchedResultsController.performFetch(nil)
        
        if sharedTransport.stopFetchedResultsController.fetchedObjects?.count > 0 {
            for index in 1...sharedTransport.stopFetchedResultsController.fetchedObjects!.count {
                var stop = sharedTransport.stopFetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: index - 1, inSection: 0)) as! Stops
                Helper.addStopPin(stop, ToMap: stopsMapView)
            }
        }
        
        sharedTransport.timeTableFetchedResultsController.performFetch(nil)
        
        if NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.Latitude) != 0 {
            stopsMapView.setRegion(MKCoordinateRegionMake(CLLocationCoordinate2DMake(NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.Latitude), NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.Longitude)), MKCoordinateSpanMake(NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.LatitudeDelta), NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.LongitudeDelta))), animated: false)
        }
    }
    
    func handleTimeTableCompleteNotification(notification: NSNotification) -> Void {
        //println("Notification received")
        if self.sharedTransport.timeTableStops.count == 0 && self.sharedTransport.requestFetchMode == .Default {
            self.sharedTransport.timeTableStops = self.stopsShownInMap()
        }
        
        //If the request is done by the Watch, set the region of the map to User Location
        if self.sharedTransport.requestFetchMode == .Watch {
            Helper.setMapRegion(self.stopsMapView, withCoordinates: self.sharedTransport.userCurrentLocation!.coordinate, delta: nil, animated: true)
        }
        
        var auxDelegate = self.sharedTransport.timeTableFetchedResultsController.delegate
        
        self.sharedTransport.timeTableFetchedResultsController = self.sharedTransport.refreshTimeTableFetchedResultsController()
        
        self.sharedTransport.timeTableFetchedResultsController.delegate = auxDelegate
        
        var error:NSError?
        
        self.sharedTransport.timeTableFetchedResultsController.performFetch(&error)
        
        self.sharedTransport.sortedTimeTable = self.sharedTransport.timeTableFetchedResultsController.fetchedObjects as? [Timetable]
        
        self.updateTableData()
    }
    
    func handleTimeTablePartialNotification(notification: NSNotification) -> Void {
        var stopProcessed = notification.object as! Int
        
        if stopProcessed < 4 {
            handleTimeTableCompleteNotification(notification)
        }
    }
    
    @IBAction func refreshTimetable(sender: AnyObject) {
        fetchData(sender)
    }
    @IBAction func setMapToUserLocation(sender: AnyObject) {
        if sharedTransport.userCurrentLocation != nil {
            Helper.setMapRegion(self.stopsMapView, withCoordinates: sharedTransport.userCurrentLocation!.coordinate, delta: nil, animated: true)
            refreshTimetable(sender)
        }
    }
    
    
    func refreshTableViewCells(timer:NSTimer) {
        if sharedTransport.centerLocation == nil {
            return
        }
        
        for cell in nextDeparturesTable.visibleCells() {
            if cell is DepartureTableViewCell {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    (cell as! DepartureTableViewCell).refreshInformationWithLocation(self.sharedTransport.userCurrentLocation!)
                })
            }
        }
    }
    
    func stopsShownInMap () -> NSArray {
        
        var rect = stopsMapView.annotationVisibleRect
        
        var mapRect = MKMapRectMake(Double(rect.origin.x), Double(rect.origin.y), Double(rect.width), Double(rect.height))
        
        println("Stops in Map \(self.stopsMapView.annotationsInMapRect(stopsMapView.visibleMapRect).count)")
        
        var annotationsInMap = self.stopsMapView.annotationsInMapRect(stopsMapView.visibleMapRect)
        
        var stopsArray = NSMutableArray()
        
        for annotation in annotationsInMap {
            if annotation is StopAnnotation {
                stopsArray.addObject((annotation as! StopAnnotation).stop)
            }
        }
        
        if annotationsInMap.count < 10 {
            return Stops.stopIdsInArray(stopsArray)
        }
        
        stopsArray.sortUsingComparator { (a, b) -> NSComparisonResult in
            var a1 = a as! Stops
            var b1 = b as! Stops
            
            var a1Distance = self.sharedTransport.centerLocation?.distanceFromLocation(a1.location)
            var b1Distance = self.sharedTransport.centerLocation?.distanceFromLocation(b1.location)
            
            if a1Distance == b1Distance {
                return NSComparisonResult.OrderedSame
            } else if (a1Distance < b1Distance) {
                return NSComparisonResult.OrderedAscending
            }
            
            return NSComparisonResult.OrderedDescending
        }
        
        return Stops.stopIdsInArray(stopsArray.subarrayWithRange(NSMakeRange(0, min(10,stopsArray.count))))
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if selectedIndex != nil {
            self.nextDeparturesTable.deselectRowAtIndexPath(selectedIndex!, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Location Manager Delegate
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else if status == CLAuthorizationStatus.NotDetermined && IS_OS_8_OR_LATER {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        
        if sharedTransport.centerLocation == nil {
            sharedTransport.centerLocation = location
        }
        
        if fetchForFirstTime == false {
            var deltaValue : Double? = nil
            
            //Set delta value selected by user if a delta has been set.
            if NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.LatitudeDelta) != 0 {
                deltaValue = NSUserDefaults.standardUserDefaults().doubleForKey(MapKeys.LatitudeDelta)
            }
            
            Helper.setMapRegion(self.stopsMapView, withCoordinates: location.coordinate, delta: deltaValue, animated: true)
        }
        
        var distance = sharedTransport.centerLocation?.distanceFromLocation(location)
        
        //println("Distance: \(distance)")
        
        if (0 < distance && distance < 100 && fetchForFirstTime == false) {
            fetchForFirstTime = true
            Helper.updateCurrentView(self.view, withActivityIndicator: self.activityIndicator, andAnimate: true)
            self.sharedTransport.fetchDataForLocation(.Default, location: location, andStops:nil, completionHandler: { (result, error) -> Void in
            })
        }
    }
    
    func fetchData(sender:AnyObject) {
        Helper.updateCurrentView(self.view, withActivityIndicator: self.activityIndicator, andAnimate: true)
        self.sharedTransport.fetchDataForLocation(.Default, location: CLLocation(latitude: stopsMapView.centerCoordinate.latitude, longitude: stopsMapView.centerCoordinate.longitude), andStops: stopsShownInMap()) { (result, error) -> Void in
        }
    }
    
    func updateTableData() {
        dispatch_async(dispatch_get_main_queue()) {
            Helper.updateCurrentView(self.view, withActivityIndicator: self.activityIndicator, andAnimate: false)
            self.nextDeparturesTable.reloadData()
            self.tableRefreshControl.endRefreshing()
        }
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "stopPin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            
            //Prepare disclosure button that will be added to the pin
            //var disclosureButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
            //disclosureButton.addTarget(self, action: Selector("showStopOptions:"), forControlEvents: UIControlEvents.TouchUpInside)
            
            //pinView!.rightCalloutAccessoryView = disclosureButton
            
            pinView!.canShowCallout = true
            //pinView!.draggable = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        println("Select annotation")
        
        //Grab the stop associated to the annotation
        var selectedStop = (view.annotation as! StopAnnotation).stop
        
        self.sharedTransport.timeTableStops = [NSNumber(int: selectedStop.stopId)]
        sharedTransport.requestFetchMode = TransportManager.TimetableFetchMode.UniqueStop
        
        //Refresh data in FetchRequestController based on the Stop selected
        var auxDelegate = self.sharedTransport.timeTableFetchedResultsController.delegate
        
        self.sharedTransport.timeTableFetchedResultsController = self.sharedTransport.refreshTimeTableFetchedResultsController()
        
        self.sharedTransport.timeTableFetchedResultsController.delegate = auxDelegate
        
        var error:NSError?
        
        self.sharedTransport.timeTableFetchedResultsController.performFetch(&error)
        
        self.sharedTransport.sortedTimeTable = self.sharedTransport.timeTableFetchedResultsController.fetchedObjects as? [Timetable]
        
        //If there is no data for the Stop, retrieve it from the API
        if self.sharedTransport.sortedTimeTable?.count == 0 {
            Helper.updateCurrentView(self.view, withActivityIndicator: self.activityIndicator, andAnimate: true)
            self.sharedTransport.fetchDataForStop(selectedStop, completionHandler: { (result, error) -> Void in
                println("Retrieving data for Selected stop")
            })
        }
        
        self.updateTableData()
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        sharedTransport.centerLocation = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        //Save map location in User defaults
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.latitude, forKey: MapKeys.Latitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.centerCoordinate.longitude, forKey: MapKeys.Longitude)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta, forKey: MapKeys.LatitudeDelta)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta, forKey: MapKeys.LongitudeDelta)
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            if anObject is Timetable {
                //Handle Timetable object
                var timeTable = anObject as! Timetable
                
                switch type {
                case .Insert:
                    println("Insert item")
                    //addPinToMap(location)
                    //self.nextDeparturesTable.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                //case .Update:
                    //println("Update item")
                default:
                    return
                }
            } else if anObject is Stops {
                //Handle Stop object
                var stop = anObject as! Stops
                
                switch type {
                case .Insert:
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        Helper.addStopPin(stop, ToMap: self.stopsMapView)
                    })
                    
                default:
                    return
                }
            }
    }
    
    //MARK: TableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sharedTransport.sortedTimeTable != nil && sharedTransport.centerLocation != nil {
            return sharedTransport.sortedTimeTable!.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var item = sharedTransport.sortedTimeTable![indexPath.row]
        
        let reuseIdentifier = "DepartureCell"
        
        var cell : DepartureTableViewCell
        
        if let tempCell: DepartureTableViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as? DepartureTableViewCell {
            
            cell = tempCell
        } else {
            cell = DepartureTableViewCell()
        }
        
        cell.updateInformationWithTimetable(item, FromLocation: sharedTransport.userCurrentLocation!)
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showStopRouteDetails" {
            selectedIndex = nextDeparturesTable.indexPathForCell((sender as! DepartureTableViewCell))
            
            var srdVC = segue.destinationViewController as! StopRouteDetailsViewController
            
            srdVC.timeTable = sharedTransport.sortedTimeTable![selectedIndex!.row]
            
        }
    }
}

