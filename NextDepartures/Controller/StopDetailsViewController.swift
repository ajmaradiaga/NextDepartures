//
//  StopDetailsViewController.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 26/06/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit
import CoreData

class StopDetailsViewController: UITableViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var selectedStop: Stops!
    
    var scheduledTimer = NSTimer()
    var selectedIndex : NSIndexPath?
    var tableRefreshControl = UIRefreshControl()
    var serviceActions : UIAlertController!
    
    var isRefreshingData : Bool = false
    var fetchForFirstTime : Bool = false
    
    var timetableElements : [Timetable]?
    
    var alertVC: UIAlertController?
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    var sharedTransport : TransportManager {
        return TransportManager.sharedInstance();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Do any additional setup after loading the view.
        self.navigationItem.title = String(format: "%@", selectedStop.locationName)
        self.navigationItem.titleView = Helper.titleViewWithText(selectedStop.locationName, andSubtitle: String(selectedStop.suburb))
        
        println("Width Title: \(self.navigationItem.titleView?.frame.width)")
        
        var transportMode = PTVClient.TransportMode.transportModeFromString(selectedStop.transportType)
        
        var color = PTVClient.TransportMode.colorForTransportType(selectedStop.transportType)
        
        self.navigationController?.navigationBar.barTintColor = color
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        //Drag to refresh control of the TableView
        tableRefreshControl.addTarget(self, action:"fetchData:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(tableRefreshControl)
        
        //Timer that refresh the time value in the TableView
        self.scheduledTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: Selector("refreshTableViewCells:"), userInfo: nil, repeats: true)
        
        sharedTransport.requestFetchMode = .UniqueStop
        sharedTransport.timeTableStops = [selectedStop]
        
        sharedTransport.timeTableFetchedResultsController = sharedTransport.refreshTimeTableFetchedResultsController()
        sharedTransport.timeTableFetchedResultsController.performFetch(nil)
        
        if sharedTransport.timeTableFetchedResultsController.fetchedObjects?.count < 25 {
            self.tableView.setContentOffset(CGPointMake(0, -self.tableRefreshControl.frame.size.height), animated: true)
            tableRefreshControl.beginRefreshing()
            fetchData(nil)
        } else {
            self.timetableElements = sharedTransport.timeTableFetchedResultsController.fetchedObjects as? [Timetable]
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if sharedTransport.isRefreshingData {
            Helper.updateCurrentView(self.view, withActivityIndicator: self.activityIndicator, andAnimate: true)
        }
    }
    
    func fetchData(sender:AnyObject?) {
        if (self.isViewLoaded() && self.view.window != nil) {
            // viewController is visible
            Helper.updateCurrentView(self.view, withActivityIndicator: self.activityIndicator, andAnimate: true)
        }
        sharedTransport.fetchDataForStop(selectedStop, completionHandler: { (result, error) -> Void in
            if error != nil {
                Helper.updateCurrentView(self.view, withActivityIndicator: self.activityIndicator, andAnimate: false)
                self.alertVC = Helper.raiseInformationalAlert(inViewController: self, withTitle: "Error", message: error!.localizedFailureReason!, completionHandler: { (alertAction) -> Void in
                    self.alertVC!.dismissViewControllerAnimated(true, completion: nil)
                })
            } else {
                //Process the timetable elements. result contains an array of Timetable
                
                self.sharedTransport.timeTableFetchedResultsController = self.sharedTransport.refreshTimeTableFetchedResultsController()
                self.sharedTransport.timeTableFetchedResultsController.performFetch(nil)
                
                self.timetableElements = self.sharedTransport.timeTableFetchedResultsController.fetchedObjects as? [Timetable]
                
                var uniqueStops : Set<String> = []
                
                if self.selectedStop.servicesList == nil {
                    for item in self.timetableElements! {
                        uniqueStops.insert(String(item.line.lineNumber))
                    }
                    
                    var uniqueStopsArray = Array(uniqueStops)
                    uniqueStopsArray.sort({ first, second in return first < second })
                    
                    self.selectedStop.servicesList = ", ".join(uniqueStopsArray)
                    
                    self.sharedContext.save(nil)
                }
                
                //sharedTransport.timeTableFetchedResultsController contains all the timeTableElements recently fetch
                self.updateTableData()
            }
        })
    }
    
    func refreshTableViewCells(timer:NSTimer) {
        if sharedTransport.centerLocation == nil {
            return
        }
        
        for cell in self.tableView.visibleCells() {
            if cell is DepartureTableViewCell {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    (cell as! DepartureTableViewCell).refreshInformationWithLocation(self.sharedTransport.userCurrentLocation!)
                })
            }
        }
    }
    
    func handleTimeTableCompleteNotification(notification: NSNotification) -> Void {
        //println("Notification received")
        
        
        var auxDelegate = self.sharedTransport.timeTableFetchedResultsController.delegate
        
        self.sharedTransport.timeTableFetchedResultsController = self.sharedTransport.refreshTimeTableFetchedResultsController()
        
        self.sharedTransport.timeTableFetchedResultsController.delegate = auxDelegate
        
        var error:NSError?
        
        self.sharedTransport.timeTableFetchedResultsController.performFetch(&error)
        
        self.sharedTransport.sortedTimeTable = self.sharedTransport.timeTableFetchedResultsController.fetchedObjects as? [Timetable]
        
        //self.updateTableData()
    }
    
    func updateTableData() {
        dispatch_async(dispatch_get_main_queue()) {
            Helper.updateCurrentView(self.view, withActivityIndicator: self.activityIndicator, andAnimate: false)
            self.tableView.reloadData()
            self.tableRefreshControl.endRefreshing()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if timetableElements == nil {
            return 0
        }
        
        return timetableElements!.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var item = timetableElements![indexPath.row]
        
        let reuseIdentifier = "DepartureCellStandard"
        
        var cell : DepartureTableViewCell
        
        if let tempCell: DepartureTableViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as? DepartureTableViewCell {
            
            cell = tempCell
        } else {
            cell = DepartureTableViewCell()
        }
        
        if sharedTransport.userCurrentLocation != nil {
            cell.updateInformationWithTimetable(item, FromLocation: self.sharedTransport.userCurrentLocation!)
        }

        return cell
    }
    
    //MARK: TableViewDelegate
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
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
            
            var timeTableItem = self.timetableElements![indexPath.row]
            
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
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if segue.identifier == "showRouteDetails" {
            selectedIndex = self.tableView.indexPathForCell((sender as! DepartureTableViewCell))
            
            var sdVC = segue.destinationViewController as! RouteDetailsViewController
            
            sdVC.timeTable = timetableElements![selectedIndex!.row]
            
        }
    }


}
