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
    //Helper.formatDistanceToString(distance)var trackingStops : [Stops] = [Stops]()
    var locationManager = CLLocationManager()
    var alertVC : UIAlertController?
    var fetchForFirstTime = false
    
    var mapIsVisible = false
    
    var sessionTask : NSURLSessionTask?
    
    var stopsOnLine : [Stops]?
    
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
                    for item in (result as! [Stops]) {
                        Helper.addStopPin(item, ToMap: self.routeMap)
                    }
                    
                    self.routeTable.reloadData()
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
            pinView!.pinColor = MKPinAnnotationColor.Red
        case .Present:
            pinView!.pinColor = MKPinAnnotationColor.Purple
        default:
            pinView!.pinColor = MKPinAnnotationColor.Green
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if view.annotation is StopAnnotation {
            
            selectedAnnotation = view.annotation as! StopAnnotation
            
            var distance = selectedAnnotation.stop.location?.distanceFromLocation(sharedTransport.userCurrentLocation)
            
            if view is MKPinAnnotationView {
                var enableDisclosureButton = true
                
                if distance < TransportManager.Constants.MinimumDistanceFromStop || selectedAnnotation.stop.patternType != .Future {
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
                self.mapListButton.image = UIImage(named: "ListIcon")
                }, completion: { (completed) -> Void in
                    self.mapIsVisible = !self.mapIsVisible
            })
        } else {
            UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                self.routeMap.alpha = 1.0
                self.locationButton.alpha = 1.0
                self.routeTable.alpha = 0
                self.mapListButton.image = UIImage(named: "MapIcon")
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
            
            stopActions.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            
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
        
        var targetStopLocation = selectedAnnotation.stop.location
        
        var userLocation = routeMap.userLocation.location
        
        sharedTransport.addTrackingStop(selectedAnnotation.stop, forService: self.timeTable!, withDistance: distance)
        
        CoreDataStackManager.sharedInstance().saveContext()
            
            println("Added \(selectedAnnotation.stop.stopName) stop to trackingStops")
        routeMap.deselectAnnotation(selectedAnnotation, animated: false)
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
            cell.updateInformationWithStop(item, FromLocation: self.sharedTransport.userCurrentLocation!)
        }
        
        return cell
    }
    
    //MARK: TableViewDelegate
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        /*
        var shareAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Share" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
        
        let shareMenu = UIAlertController(title: nil, message: "Share using", preferredStyle: .ActionSheet)
        
        let twitterAction = UIAlertAction(title: "Twitter", style: UIAlertActionStyle.Default, handler: nil)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        shareMenu.addAction(twitterAction)
        shareMenu.addAction(cancelAction)
        
        
        self.presentViewController(shareMenu, animated: true, completion: nil)
        })
        */
        
        var actions = NSMutableArray()
        
        
        var reminderAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Reminder" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            
            var stop = self.stopsOnLine![indexPath.row]
            
            self.showStopOptions(stop)
            
            var timeDifference = timeTableItem.timeFromNow()
            
            if timeDifference > 360 {
                self.alertVC = UIAlertController(title: nil, message: "Notify Me", preferredStyle: .ActionSheet)
                
                let fiveMinutesAction = UIAlertAction(title: "5 minutes", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
                    self.setReminder(timeTableItem, seconds: 300)
                }
                let fifteenMinutesAction = UIAlertAction(title: "15 minutes", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
                    self.setReminder(timeTableItem, seconds: 900)
                }
                
                let thirtyMinutesAction = UIAlertAction(title: "30 minutes", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
                    self.setReminder(timeTableItem, seconds: 1800)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (alertAction) -> Void in
                    self.tableView.editing = false
                })
                
                self.alertVC!.addAction(fiveMinutesAction)
                
                if timeDifference > 900 {
                    self.alertVC!.addAction(fifteenMinutesAction)
                }
                
                if timeDifference > 1800 {
                    self.alertVC!.addAction(thirtyMinutesAction)
                }
                self.alertVC!.addAction(cancelAction)
                
                
                self.presentViewController(self.alertVC!, animated: true, completion: nil)
            } else {
                var serviceName = timeTableItem.transportType == "train" ? "" : "- \(timeTableItem.lineDirection.directionName)"
                
                Helper.raiseNotification("You should be @ \(timeTableItem.stop.stopName) in \(timeTableItem.displayTimeFromNow()) for service \(timeTableItem.line.lineNumber) \(serviceName)", withTitle: "Get Ready", completionHandler: { () -> Void in
                    self.tableView.editing = false
                })
            }
        })
        
        reminderAction.backgroundColor = UIColor(red: 171/255, green: 73/255, blue: 188/255, alpha: 1.0)
        
        var setDestinationAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Set Destination" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            
            var timeTableItem = self.timetableElements![indexPath.row]
            
            self.performSegueWithIdentifier("showRouteDetails", sender: self.tableView.cellForRowAtIndexPath(indexPath))
        })
        
        setDestinationAction.backgroundColor = UIColor(red: 240/255, green: 79/255, blue: 27/255, alpha: 0.8)
        
        actions.addObject(setDestinationAction)
        actions.addObject(reminderAction)
        
        return actions as [AnyObject]?
    }
    
    func setReminder(timeTableItem: Timetable, seconds: Int32) {
        self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
        println("Set Reminder: \(seconds) before.")
        TransportManager.sharedInstance().addTrackingService(timeTableItem, withSeconds: seconds)
        self.tableView.editing = false
    }
}
