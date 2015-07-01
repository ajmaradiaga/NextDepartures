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
    
    var scheduledTimer = NSTimer()
    var favouriteActions : UIAlertController!
    var favouriteStops = [Stops]()
    var favouriteColor = UIColor(red: 250/255.0, green: 207/255, blue: 55/255, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        sharedTransport.favouriteStopFetchedResultsController.delegate = self
        sharedTransport.favouriteStopFetchedResultsController.performFetch(nil)
        
        //Timer that refresh the time value in the TableView
        self.scheduledTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("refreshTableViewCells:"), userInfo: nil, repeats: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = favouriteColor
        refreshDataInView()
    }
    
    func refreshDataInView() {
        if sharedTransport.favouriteStopFetchedResultsController.fetchedObjects!.count == 0 {
            self.favouritesTableView.hidden = true
            self.favouriteStops = [Stops]()
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
            
            self.favouriteStops = tempArray as [AnyObject] as! [Stops]
            
        }
        favouritesTableView.reloadData()
    }
    
    var sharedTransport : TransportManager {
        return TransportManager.sharedInstance();
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.favouriteStops.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var item = favouriteStops[indexPath.row]
        
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
    /*
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var item = favouriteStops[indexPath.row]
        
        self.performSegueWithIdentifier("showStopDetailsFromFavourites", sender: tableView.cellForRowAtIndexPath(indexPath))
    }*/
    
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
        
        var item = self.favouriteStops[indexPath.row]
        var actions = NSMutableArray()
        
        
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
        
        return actions as [AnyObject]?
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showStopDetailsFromFavourites" {
            
            var sdVC = segue.destinationViewController as! StopDetailsViewController
            
            if sender is StopTableViewCell {
                sdVC.selectedStop = self.favouriteStops[self.favouritesTableView.indexPathForSelectedRow()!.row]
            } else {
                println("Someone else is calling")
            }
        }
    }
}


