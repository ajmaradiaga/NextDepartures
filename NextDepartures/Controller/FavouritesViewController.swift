//
//  FavouritesViewController.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 1/07/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit
import CoreData

class FavouritesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var favouritesTableView: UITableView!
    
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeigthConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftMainTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightMainTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftSubTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightSubTextConstraint: NSLayoutConstraint!
    
    var scheduledTimer = NSTimer()
    var favouriteActions : UIAlertController!
    var favouriteColor = UIColor(red: 250/255.0, green: 207/255, blue: 55/255, alpha: 1.0)
    
    var stopActions : UIAlertController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sharedTransport.favouriteStopFetchedResultsController.delegate = self
        sharedTransport.favouriteStopFetchedResultsController.performFetch(nil)
        
        //Timer that refresh the time value in the TableView
        self.scheduledTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("refreshTableViewCells:"), userInfo: nil, repeats: true)
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        var labelValue :CGFloat = leftMainTextConstraint.constant
        //var imageTopValue :CGFloat = topImageConstraint.constant
        var imageWidthHeight : CGFloat = imageWidthConstraint.constant
        
        println(UIScreen.mainScreen().bounds.size.width)
        println(UIScreen.mainScreen().bounds.size.height)
        
        if (UIScreen.mainScreen().bounds.size.width > 375.0) {
            labelValue = 50.0
        } else if (UIScreen.mainScreen().bounds.size.width < 375.0) {
            labelValue = 10.0
        //    imageTopValue = 28.0
        }
        
        //Handle < iPhone 6
        if (UIScreen.mainScreen().bounds.size.height < 559.0) {
            imageWidthHeight = 143.0
        }
        
        
        leftMainTextConstraint.constant = labelValue
        rightMainTextConstraint.constant = labelValue
        
        leftSubTextConstraint.constant = labelValue
        rightSubTextConstraint.constant = labelValue
        
        imageHeigthConstraint.constant = imageWidthHeight
        imageWidthConstraint.constant = imageWidthHeight
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = favouriteColor
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Gotham Medium", size: 17)!, NSForegroundColorAttributeName: UIColor.whiteColor()]
        refreshDataInView()
    }
    
    func refreshDataInView() {
        if sharedTransport.favouriteStopFetchedResultsController.fetchedObjects!.count == 0 {
            self.favouritesTableView.hidden = true
            sharedTransport.favouriteStops = [Stops]()
        } else {
            self.favouritesTableView.hidden = false
            
            var tempArray = NSMutableArray(array: self.sharedTransport.favouriteStopFetchedResultsController.fetchedObjects!)
            
            tempArray.sortUsingComparator { (a, b) -> NSComparisonResult in
                var a1 = a as! Stops
                var b1 = b as! Stops
                
                var a1Distance = self.sharedTransport.userCurrentLocation?.distanceFromLocation(a1.location)
                var b1Distance = self.sharedTransport.userCurrentLocation?.distanceFromLocation(b1.location)
                
                if a1Distance == b1Distance {
                    return NSComparisonResult.OrderedSame
                } else if (a1Distance < b1Distance) {
                    return NSComparisonResult.OrderedAscending
                }
                
                return NSComparisonResult.OrderedDescending
            }
            
            sharedTransport.favouriteStops = tempArray as [AnyObject] as! [Stops]
            
        }
        favouritesTableView.reloadData()
    }
    
    var sharedTransport : TransportManager {
        return TransportManager.sharedInstance();
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sharedTransport.favouriteStops.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var item = sharedTransport.favouriteStops[indexPath.row]
        
        let reuseIdentifier = "StopTableCell"
        
        var cell : StopTableViewCell
        
        if let tempCell: StopTableViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as? StopTableViewCell {
            cell = tempCell
        } else {
            cell = StopTableViewCell()
        }
        
        cell.updateInformationWithStop(item, FromLocation: sharedTransport.userCurrentLocation!)
        
        return cell
    }
    
    func showStopOptions(sender: AnyObject) {
        var stop : Stops
        
        stop = sender as! Stops
        
        stopActions = UIAlertController(title: "Notify", message: "Notify when selected stop is: ", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        
        stopActions.addAction(UIAlertAction(title: "\(Int(TransportManager.Constants.MinimumDistanceFromStop))m away", style: .Default) { (alertAction) -> Void in
            self.handleDistanceSelected(stop, distance:TransportManager.Constants.MinimumDistanceFromStop)
            })
        stopActions.addAction(UIAlertAction(title: "500m away", style: .Default) { (alertAction) -> Void in
            self.handleDistanceSelected(stop, distance:500)
            })
        stopActions.addAction(UIAlertAction(title: "1km away", style: .Default) { (alertAction) -> Void in
            self.handleDistanceSelected(stop, distance:1000)
            })
        
        stopActions.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            self.favouritesTableView.editing = false
        })
        
        self.presentViewController(stopActions, animated: true, completion: nil)
        
    }
    
    func handleDistanceSelected(stop: Stops, distance: Double) -> Void{
        sharedTransport.addTrackingStop(stop, forService: nil, withDistance: distance)
        CoreDataStackManager.sharedInstance().saveContext()
        
        println("Added \(stop.stopName) stop to trackingStops")
        
        self.favouritesTableView.editing = false
    }
    
    func refreshTableViewCells(timer:NSTimer) {
        if sharedTransport.centerLocation == nil {
            return
        }
        
        for cell in favouritesTableView.visibleCells() {
            if cell is StopTableViewCell {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    var stopCell = cell as! StopTableViewCell
                    stopCell.updateInformationWithStop(stopCell.stopItem!, FromLocation: self.sharedTransport.userCurrentLocation!)
                })
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            if anObject is Stops {
                //Handle Timetable object
                var item = anObject as! Stops
                
                switch type {
                case .Insert:
                    println("Insert item")
                    break
                case .Update:
                    println("Update item")
                    break
                case .Delete:
                    self.refreshDataInView()
                    break
                default:
                    return
                }
            }
    }
    
    //MARK: TableViewDelegate
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        var item = sharedTransport.favouriteStops[indexPath.row]
        var actions = NSMutableArray()
        
        var setDestinationAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Set Destination" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            
            var selectedStop = self.sharedTransport.favouriteStops[indexPath.row]
            
            self.showStopOptions(selectedStop)
            
        })
        
        setDestinationAction.backgroundColor = UIColor(red: 171/255, green: 73/255, blue: 188/255, alpha: 1.0)//UIColor(red: 240/255, green: 79/255, blue: 27/255, alpha: 0.8)
        
        var deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Delete" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            
            self.favouriteActions = UIAlertController(title: "Delete Favourite", message: "Are you sure you want to delete \(item.stopName)", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            
            self.favouriteActions.addAction(UIAlertAction(title: "Delete", style: .Destructive) { (alertAction) -> Void in
                
                item.favourite = false
                CoreDataStackManager.sharedInstance().saveContext()
                
                self.favouriteActions.dismissViewControllerAnimated(true, completion: nil)
            })
            
            self.favouriteActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (alertAction) -> Void in
                self.favouritesTableView.deselectRowAtIndexPath(indexPath, animated: true)
            }))
            
            self.presentViewController(self.favouriteActions, animated: true, completion: nil)
        })
        
        deleteAction.backgroundColor = UIColor(red: 243/255, green: 78/255, blue: 12/255, alpha: 1.0)
    
        actions.addObject(deleteAction)
        actions.addObject(setDestinationAction)
        
        return actions as [AnyObject]?
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showStopDetailsFromFavourites" {
            
            var sdVC = segue.destinationViewController as! StopDetailsViewController
            
            if sender is StopTableViewCell {
                sdVC.selectedStop = sharedTransport.favouriteStops[self.favouritesTableView.indexPathForSelectedRow()!.row]
            } else {
                println("Someone else is calling")
            }
        }
    }
}


