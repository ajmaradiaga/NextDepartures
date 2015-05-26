//
//  TrackingStopTableViewCell.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 21/05/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit

class TrackingStopTableViewCell: UITableViewCell {

    @IBOutlet weak var enabledSwitch : UISwitch!
    
    @IBOutlet weak var stopDetailsLabel : UILabel!
    @IBOutlet weak var trackingDistanceLabel : UILabel!
    
    var trackingStop : TrackingStop?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateInformationWithTrackingStop(item: TrackingStop) {
        /*if accessoryView == nil {
            accessoryView = enabledSwitch
        }*/
        trackingStop = item
        enabledSwitch.on = item.enabled
        stopDetailsLabel.text = item.stop.stopName
        
        var currentDistanceString =  ""
        
        if TransportManager.sharedInstance().userCurrentLocation != nil {
            currentDistanceString = " - Current Distance: \(Helper.formatDistanceToString(item.stop.location!.distanceFromLocation(TransportManager.sharedInstance().userCurrentLocation)))"
        }
        
        trackingDistanceLabel.text = "Alert: \(Helper.formatDistanceToString(item.trackingDistance))\(currentDistanceString)"
    }
    
    @IBAction func switchValueChanges(sender: AnyObject) {
        trackingStop?.enabled = enabledSwitch.on
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
}
