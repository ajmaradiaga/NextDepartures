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

class RouteDetailsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var timeTable : Timetable!
    var selectedAnnotation : StopAnnotation!
    //Helper.formatDistanceToString(distance)var trackingStops : [Stops] = [Stops]()
    var locationManager = CLLocationManager()
    var alertVC : UIAlertController?
    var fetchForFirstTime = false
    
    var sessionTask : NSURLSessionTask?
    
    var stopsOnLine : [Stops]?
    
    var stopActions : UIAlertController!
    
    var sharedTransport : TransportManager {
        return TransportManager.sharedInstance();
    }
    
    @IBOutlet weak var routeMap: MKMapView!
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
    
    func showStopOptions(sender: AnyObject) {
        
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
    }
    
    func handleDistanceSelected(distance: Double) -> Void{
        stopActions.dismissViewControllerAnimated(true, completion: nil)
        
        var targetStopLocation = selectedAnnotation.stop.location
        
        var userLocation = routeMap.userLocation.location
        
        sharedTransport.addTrackingStop(selectedAnnotation.stop, forService: self.timeTable!, withDistance: distance)
            
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
    /*
    lazy var stopFetchRequest : NSFetchRequest = {
        let fetchRequest = NSFetchRequest(entityName: "Stops")
        
        fetchRequest.predicate = NSPredicate(format: "\(Stops.Keys.Line).\(Line.Keys.LineId) == %i", self.timeTable.line.lineId)
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Stops.Keys.StopId, ascending: true)]
        
        return fetchRequest
    }()
    
    //MARK: NSFetchedResults Delegate
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = self.stopFetchRequest
        
        //println("Objects in Stops: \(self.sharedContext.countForFetchRequest(fetchRequest, error:nil))")
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            var timeTable = anObject as! Timetable
            
            switch type {
            case .Insert:
                println("Insert item")
                //addPinToMap(location)
            default:
                return
            }
    }*/
    
    //MARK: TableViewDataSource
    /*
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.sharedContext.countForFetchRequest(stopFetchRequest, error: nil) > 0 {
            return self.fetchedResultsController.fetchedObjects!.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var item = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Timetable
        
        let reuseIdentifier = "DepartureCell"
        
        var cell : DepartureTableViewCell
        
        if let tempCell: DepartureTableViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as? DepartureTableViewCell {
            
            cell = tempCell
        } else {
            cell = DepartureTableViewCell()
        }
        
        //cell.lineNumberLabel.text = item.line.lineNumber
        cell.subTextLabel.text = item.line.lineName
        cell.mainTextLabel.text = item.destinationName
        
        var displayTime = ""
        var timeSince = item.timeUTC.timeIntervalSinceDate(NSDate())
        
        var timeValue : Double = 0
        var timeDescription : String = "secs"
        
        if timeSince < 60 && timeSince > 0 {
            timeValue = timeSince
        } else if timeSince > 60 && timeSince < 3600 {
            timeValue = timeSince / 60
            timeDescription = "mins"
        } else if timeSince > 3600 {
            timeValue = timeSince / 3600
            timeDescription = "hours"
        } else {
            displayTime = "0"
        }
        
        displayTime = String(format: "%0.0f %@", timeValue, timeDescription)
        
        cell.upperRightTextLabel.text = displayTime
        let distance = item.stop.location!.distanceFromLocation(currentLocation!)
        cell.rightTextLabel.text = String(format:"%.1f m", distance)
        
        return cell
    }*/
}
