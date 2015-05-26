//
//  SecondViewController.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 19/04/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit
import CoreData

class TrackingStopsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var trackingTableView: UITableView!
    
    var scheduledTimer = NSTimer()
    var trackingActions : UIAlertController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sharedTransport.trackingStopFetchedResultsController.delegate = self
        sharedTransport.trackingStopFetchedResultsController.performFetch(nil)
        
        //Timer that refresh the time value in the TableView
        self.scheduledTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("refreshTableViewCells:"), userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        trackingTableView.reloadData()
    }
    
    var sharedTransport : TransportManager {
        return TransportManager.sharedInstance();
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sharedTransport.trackingStopFetchedResultsController.fetchedObjects!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var item = sharedTransport.trackingStopFetchedResultsController.objectAtIndexPath(indexPath) as! TrackingStop
        
        let reuseIdentifier = "TrackingStopCell"
        
        var cell : TrackingStopTableViewCell
        
        if let tempCell: TrackingStopTableViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as? TrackingStopTableViewCell {
            
            cell = tempCell
        } else {
            cell = TrackingStopTableViewCell()
        }
        
        cell.updateInformationWithTrackingStop(item)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var item = sharedTransport.trackingStopFetchedResultsController.objectAtIndexPath(indexPath) as! TrackingStop
        
        trackingActions = UIAlertController(title: "Remove Stop", message: "Do you want to remove \(item.stop.stopName)", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        
        trackingActions.addAction(UIAlertAction(title: "Remove", style: .Destructive) { (alertAction) -> Void in
            CoreDataStackManager.sharedInstance().managedObjectContext!.deleteObject(self.sharedTransport.trackingStopFetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            CoreDataStackManager.sharedInstance().saveContext()
            self.trackingActions.dismissViewControllerAnimated(true, completion: nil)
            })
        
        trackingActions.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (alertAction) -> Void in
            self.trackingTableView.deselectRowAtIndexPath(indexPath, animated: true)
        }))
        
        self.presentViewController(trackingActions, animated: true, completion: nil)
    }
    
    func refreshTableViewCells(timer:NSTimer) {
        if sharedTransport.centerLocation == nil {
            return
        }
        
        for cell in trackingTableView.visibleCells() {
            if cell is TrackingStopTableViewCell {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    var trackingStopCell = (cell as! TrackingStopTableViewCell)
                    trackingStopCell.updateInformationWithTrackingStop(trackingStopCell.trackingStop!)
                })
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            if anObject is TrackingStop {
                //Handle Timetable object
                var item = anObject as! TrackingStop
                
                switch type {
                case .Insert:
                    println("Insert item")
                    //addPinToMap(location)
                    //self.nextDeparturesTable.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
                case .Update:
                    println("Update item")
                case .Delete:
                    self.trackingTableView.reloadData()
                default:
                    return
                }
            } 
    }
}
