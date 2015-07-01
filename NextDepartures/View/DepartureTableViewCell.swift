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
    @IBOutlet weak var serviceNumber: UILabel!
    @IBOutlet weak var circleImage: UIImageView!
    
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
        var tm = PTVClient.TransportMode.transportModeFromString(item.transportType)
        
        if tm == .Train || tm == .VLine {
            mainTextLabel.text = item.line.lineNumber
            serviceNumber.text = Helper.getInitials(item.line.lineNumber)
            
            if circleImage != nil {
                if tm == .Train {
                    circleImage!.image = UIImage(named: "train_circle")!
                } else {
                    circleImage!.image = UIImage(named: "V-Line_circle")!
                }
            }
        } else {
            mainTextLabel.text = item.lineDirection.directionName
            serviceNumber.text = item.line.lineNumber
            serviceNumber.textColor = PTVClient.TransportMode.colorForTransportType(item.transportType)
        }

        subTextLabel.text = String(format:"to \(item.destinationName)")
        
        
        //transportationImageView.image = UIImage(named: PTVClient.TransportMode.imageNameForTransportType(item.transportType))
        
        timetableItem = item
        
        var timeValues = Helper.formatTime(item.timeFromNow())
        
        
        upperRightTextLabel.text = timeValues.timeValue
        
        
        let distance = item.stop.location!.distanceFromLocation(location)
        
        rightTextLabel.text = timeValues.timeUOM//Helper.formatDistanceToString(distance)
    }
    
    func refreshInformationWithLocation(location:CLLocation) {
        updateInformationWithTimetable(timetableItem!, FromLocation: location)
    }

}
