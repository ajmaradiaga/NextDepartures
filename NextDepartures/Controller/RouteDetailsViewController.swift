//
//  StopRouteDetailsViewController.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 25/04/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class RouteDetailsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {

    var timeTable : Timetable!
    var selectedAnnotation : StopAnnotation!
    var selectedStop : Stops!
    //Helper.formatDistanceToString(distance)var trackingStops : [Stops] = [Stops]()
    var locationManager = CLLocationManager()
    var alertVC : UIAlertController?
    var fetchForFirstTime = false
    
    var mapIsVisible = false
    
    var sessionTask : NSURLSessionTask?
    
    var stopsOnLine : [Stops]?
    var presentStopIndex = 0
    
    var stopActions : UIAlertController!
    
    var sharedTransport : TransportManager {
        return TransportManager.sharedInstance();
    }
    
    @IBOutlet var routeTable: UITableView!
    @IBOutlet var routeMap: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var mapListButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currentLocation : CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navigationItem.titleView = Helper.titleViewWithText(String(format: "%@ - %@", timeTable.line.lineNumber, timeTable.lineDirection.directionName), andSubtitle: "Select your destination")

        Helper.setMapRegion(routeMap, withCoordinates: timeTable.stop.location!.coordinate, delta: 0.01, animated: true)
        
        timeTable.stop.patternType = .Present
        
        Helper.addStopPin(timeTable.stop, ToMap: routeMap)
        
        sessionTask = PTVClient.sharedInstance().stoppingPattern(timeTable, completionHandler: { (result, error) -> Void in
            println("Refreshed stops on Line")
            
            if result != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.stopsOnLine = result as? [Stops]
                    
                    
                    
                    for (index, item) in enumerate(result as! [Stops]) {
                        Helper.addStopPin(item, ToMap: self.routeMap)
                        
                        if item.patternType == .Present {
                            self.presentStopIndex = index
                        }
                    }
                    
                    self.routeTable.reloadData()
                    
                    self.routeTable.scrollToRowAtIndexPath(NSIndexPath(forRow: self.presentStopIndex, inSection: 0), atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                Helper.updateCurrentView(self.view, withActivityIndicator: self.activityIndicator, andAnimate: false)
            }
            
            if error != nil {
                self.alertVC = Helper.raiseInformationalAlert(inViewController: self, withTitle: "Error", message: error!.description, completionHandler: { (alertAction) -> Void in
                    self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
                })
            }
            
        })
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        dispatch_async(dispatch_get_main_queue()) {
            if self.stopsOnLine == nil {
                Helper.updateCurrentView(self.view, withActivityIndicator: self.activityIndicator, andAnimate: true)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func setRouteMap () {
        var location = timeTable.stop.location!

        Helper.setMapRegion(routeMap, withCoordinates: timeTable.stop.location!.coordinate, delta: 0.01, animated: true)
        
        Helper.addStopPin(timeTable.stop, ToMap: routeMap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            var disclosureButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
            disclosureButton.addTarget(self, action: Selector("showStopOptions:"), forControlEvents: UIControlEvents.TouchUpInside)
            
            pinView!.rightCalloutAccessoryView = disclosureButton
            pinView!.canShowCallout = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        var pinStop = (annotation as! StopAnnotation).stop
        
        switch pinStop.patternType {
        case .Past:
            pinView!.image = UIImage(named: "Stop_passed")!
        case .Present:
            pinView!.image = UIImage(named: "Stop_current")!
        default:
            pinView!.image = UIImage(named: "\(timeTable.stop.transportType)_future")!
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if view.annotation is StopAnnotation {
            
            selectedAnnotation = view.annotation as! StopAnnotation
            
            selectedStop = selectedAnnotation.stop
            
            var distance = selectedStop.location?.distanceFromLocation(sharedTransport.userCurrentLocation)
            
            if view is MKPinAnnotationView {
                var enableDisclosureButton = true
                
                if distance < TransportManager.Constants.MinimumDistanceFromStop || selectedStop.patternType != .Future {
                    enableDisclosureButton = false
                }
                
                ((view as! MKPinAnnotationView).rightCalloutAccessoryView as! UIButton).enabled = enableDisclosureButton
            }
        }
        
    }
    
    @IBAction func setMapToUserLocation(sender: AnyObject) {
        if sharedTransport.userCurrentLocation != nil {
            Helper.setMapRegion(self.routeMap, withCoordinates: sharedTransport.userCurrentLocation!.coordinate, delta: nil, animated: true)
        }
    }
    
    
    @IBAction func toggleMapTableView(sender: AnyObject) {
        if mapIsVisible == true {
            UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                self.routeMap.alpha = 0
                self.locationButton.alpha = 0
                self.routeTable.alpha = 1.0
                self.mapListButton.image = UIImage(named: "MapIcon")
                }, completion: { (completed) -> Void in
                    self.mapIsVisible = !self.mapIsVisible
            })
        } else {
            UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                self.routeMap.alpha = 1.0
                self.locationButton.alpha = 1.0
                self.routeTable.alpha = 0
                self.mapListButton.image = UIImage(named: "ListIcon")
                }, completion: { (completed) -> Void in
                    self.mapIsVisible = !self.mapIsVisible
            })
        }
    }
    
    func showStopOptions(sender: AnyObject) {
        var stop : Stops
        
        if sender is Stops {
            stop = sender as! Stops
        } else {
            stop = selectedAnnotation.stop
        }
        
        if stop.patternType == .Future {
            stopActions = UIAlertController(title: "Notify", message: "Notify when selected stop is: ", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            
            stopActions.addAction(UIAlertAction(title: "\(Int(TransportManager.Constants.MinimumDistanceFromStop))m away", style: .Default) { (alertAction) -> Void in
                self.handleDistanceSelected(TransportManager.Constants.MinimumDistanceFromStop)
                })
            stopActions.addAction(UIAlertAction(title: "500m away", style: .Default) { (alertAction) -> Void in
                self.handleDistanceSelected(500)
                })
            stopActions.addAction(UIAlertAction(title: "1km away", style: .Default) { (alertAction) -> Void in
                self.handleDistanceSelected(1000)
                })
            
            stopActions.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
                self.setViewInNormalState()
            })
            
            self.presentViewController(stopActions, animated: true, completion: nil)
        } else {
            //Called by the Map
            if !(sender is Stops) {
                routeMap.deselectAnnotation(selectedAnnotation, animated: true)
            }
        }
    }
    
    func handleDistanceSelected(distance: Double) -> Void{
        //stopActions.dismissViewControllerAnimated(true, completion: nil)
        
        var targetStopLocation = selectedStop.location
        
        var userLocation = routeMap.userLocation.location
        
        sharedTransport.addTrackingStop(selectedStop, forService: self.timeTable!, withDistance: distance)
        
        CoreDataStackManager.sharedInstance().saveContext()
            
        println("Added \(selectedStop.stopName) stop to trackingStops")
        
        setViewInNormalState()
    }
    
    func setViewInNormalState() {
        if mapIsVisible {
            routeMap.deselectAnnotation(selectedAnnotation, animated: false)
        } else {
            routeTable.editing = false
            if routeTable.indexPathForSelectedRow() != nil {
                routeTable.deselectRowAtIndexPath(routeTable.indexPathForSelectedRow()!, animated: true)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        if fetchForFirstTime == false {
            fetchForFirstTime = true
        }
    }
    
    //MARK: CoreData
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if self.stopsOnLine == nil {
            return 0
        }
        
        return self.stopsOnLine!.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var item = self.stopsOnLine![indexPath.row]
        var tm = PTVClient.TransportMode.transportModeFromString(item.transportType)
        
        let reuseIdentifier = "RouteStop"
        
        var cell : RouteStopTableViewCell
        
        if let tempCell: RouteStopTableViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as? RouteStopTableViewCell {
            
            cell = tempCell
        } else {
            cell = RouteStopTableViewCell()
        }
        
        if sharedTransport.userCurrentLocation != nil {
            cell.updateInformationWithStop(item, fromLocation: self.sharedTransport.userCurrentLocation!, itemIndex: indexPath.row, presentIndex: self.presentStopIndex, lastIndex: self.stopsOnLine!.count - 1)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.showStopOptions(self.stopsOnLine![indexPath.row])
    }
    
    //MARK: TableViewDelegate
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        
        var actions = NSMutableArray()
        
        var setDestinationAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Set Destination" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            
            self.selectedStop = self.stopsOnLine![indexPath.row]
            
            if self.selectedStop.patternType == .Future {
                self.showStopOptions(self.selectedStop)
            }
            
        })
        
        setDestinationAction.backgroundColor = UIColor(red: 171/255, green: 73/255, blue: 188/255, alpha: 1.0)//UIColor(red: 240/255, green: 79/255, blue: 27/255, alpha: 0.8)
        
        actions.addObject(setDestinationAction)
        
        return actions as [AnyObject]?
    }
    
    func setReminder(timeTableItem: Timetable, seconds: Int32) {
        self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
        println("Set Reminder: \(seconds) before.")
        TransportManager.sharedInstance().addTrackingService(timeTableItem, withSeconds: seconds)
        //self.tableView.editing = false
    }
}
