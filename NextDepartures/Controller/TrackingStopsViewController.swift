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
    
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftMainTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightMainTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftSubTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightSubTextConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var trackingEmptyStateMainText: UILabel!
    @IBOutlet weak var trackingEmptyStateSubText: UILabel!
    
    var scheduledTimer = NSTimer()
    var trackingActions : UIAlertController!
    var trackingColor = UIColor(red: 170/255.0, green: 74/255, blue: 188/255, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sharedTransport.trackingStopFetchedResultsController.delegate = self
        sharedTransport.trackingStopFetchedResultsController.performFetch(nil)
        
        //Timer that refresh the time value in the TableView
        self.scheduledTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("refreshTableViewCells:"), userInfo: nil, repeats: true)
        
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .Center
        
        var attrString = NSMutableAttributedString(string: trackingEmptyStateMainText.text!)
        
        attrString.addAttributes([NSParagraphStyleAttributeName:paragraphStyle, NSFontAttributeName:UIFont(name: "Gotham Medium", size: 19.0)!], range: NSMakeRange(0, attrString.length))
        
        self.trackingEmptyStateMainText.attributedText = attrString
        
        attrString = NSMutableAttributedString(string: trackingEmptyStateSubText.text!)
        
        paragraphStyle.lineSpacing = 3
        
        attrString.addAttributes([NSParagraphStyleAttributeName:paragraphStyle, NSFontAttributeName:UIFont(name: "Gotham", size: 14.0)!], range: NSMakeRange(0, attrString.length))
        
        
        self.trackingEmptyStateSubText.attributedText = attrString
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        var labelValue :CGFloat = leftMainTextConstraint.constant
        var imageWidthHeight : CGFloat = imageWidthConstraint.constant
        
        //println(UIScreen.mainScreen().bounds.size.width)
        //println(UIScreen.mainScreen().bounds.size.height)
        
        if (UIScreen.mainScreen().bounds.size.width > 375.0) {
            labelValue = 50.0
        } else if (UIScreen.mainScreen().bounds.size.width < 375.0) {
            labelValue = 10.0
        }
        
        //Handle < iPhone 6
        if (UIScreen.mainScreen().bounds.size.height < 559.0) {
            imageWidthHeight = 143.0
        }
        
        
        leftMainTextConstraint.constant = labelValue
        rightMainTextConstraint.constant = labelValue
        
        leftSubTextConstraint.constant = labelValue
        rightSubTextConstraint.constant = labelValue
        
        imageHeightConstraint.constant = imageWidthHeight
        imageWidthConstraint.constant = imageWidthHeight
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Gotham Medium", size: 17)!, NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController?.navigationBar.barTintColor = trackingColor
        refreshDataInView()
    }
    
    func refreshDataInView() {
        if sharedTransport.trackingStopFetchedResultsController.fetchedObjects!.count == 0 {
            self.trackingTableView.hidden = true
        } else {
            self.trackingTableView.hidden = false
        }
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
            if cell.enabledSwitch == nil {
                cell.prepareSwitch()
            }
        } else {
            cell = TrackingStopTableViewCell()
            cell.prepareSwitch()
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
}

