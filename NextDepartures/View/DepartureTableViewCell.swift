//
//  DepartureTableViewCell.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 25/04/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit
import MapKit

class DepartureTableViewCell: UITableViewCell {

    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var subTextLabel: UILabel!
    @IBOutlet weak var upperRightTextLabel: UILabel!
    @IBOutlet weak var rightTextLabel: UILabel!
    @IBOutlet weak var transportationImageView: UIImageView!
    
    var timetableItem : Timetable?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateInformationWithTimetable(item: Timetable, FromLocation location: CLLocation) {
        //lineNumberLabel.text = item.line.lineNumber
        
        subTextLabel.text = String(item.stop.stopId) + " - " + item.stop.locationName
        mainTextLabel.text = String(item.line.lineNumber) + " - " + item.lineDirection.directionName
        
        transportationImageView.image = UIImage(named: PTVClient.TransportMode.imageNameForTransportType(item.transportType))
        
        timetableItem = item
        
        var displayTime = item.displayTimeFromNow()
        
        
        upperRightTextLabel.text = displayTime
        
        let distance = item.stop.location!.distanceFromLocation(location)
        
        rightTextLabel.text = Helper.formatDistanceToString(distance)
    }
    
    func refreshInformationWithLocation(location:CLLocation) {
        updateInformationWithTimetable(timetableItem!, FromLocation: location)
    }

}
