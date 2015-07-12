//
//  RouteStopTableViewCell.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 8/07/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit
import MapKit

class RouteStopTableViewCell: UITableViewCell {
    
    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var subTextLabel: UILabel!
    @IBOutlet weak var stopPatternTypeImageView: UIImageView!
    
    @IBOutlet weak var stopPatternPreviousImageView: UIImageView!
    @IBOutlet weak var stopPatternNextImageView: UIImageView!
    var stopItem : Stops?
    
    var currentColour = UIColor(red: 240/255, green: 79/255, blue: 27/255, alpha: 1.0)
    var passedColour = UIColor(red: 206/255, green: 206/255, blue: 206/255, alpha: 1.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateInformationWithStop(item: Stops, fromLocation location: CLLocation, itemIndex: Int, presentIndex: Int, lastIndex: Int) {
        stopItem = item
    
        mainTextLabel.text = item.locationName
        
        if item.patternType == .Future {
            
            stopPatternTypeImageView.image = UIImage(named: "\(item.transportType)_future")!
            
            if itemIndex == presentIndex + 1 {
                stopPatternPreviousImageView.image = PTVClient.getImageWithColor(currentColour,size:CGSizeMake(5.0, 12.0))
            } else {
                stopPatternPreviousImageView.image = PTVClient.getImageWithColor(PTVClient.TransportMode.colorForTransportType(item.transportType),size:CGSizeMake(5.0, 12.0))
            }
            
            if itemIndex != lastIndex {
                stopPatternNextImageView.image =  PTVClient.getImageWithColor(PTVClient.TransportMode.colorForTransportType(item.transportType),size:CGSizeMake(5.0, 12.0))
            } else {
                stopPatternNextImageView.image =  PTVClient.getImageWithColor(UIColor.clearColor(),size:CGSizeMake(5.0, 12.0))
            }
        } else if item.patternType == .Present {
            stopPatternTypeImageView.image = UIImage(named: "Stop_current")!
            
            if itemIndex == 0 {
                stopPatternPreviousImageView.image =  PTVClient.getImageWithColor(UIColor.clearColor(),size:CGSizeMake(5.0, 12.0))
            } else {
                stopPatternPreviousImageView.image =  PTVClient.getImageWithColor(passedColour,size:CGSizeMake(5.0, 12.0))
            }
            
            stopPatternNextImageView.image =  PTVClient.getImageWithColor(currentColour,size:CGSizeMake(5.0, 12.0))
            
        } else {
            stopPatternTypeImageView.image = UIImage(named: "Stop_passed")!
            
            if itemIndex == 0 {
                stopPatternPreviousImageView.image =  PTVClient.getImageWithColor(UIColor.clearColor(),size:CGSizeMake(5.0, 12.0))
            } else {
                stopPatternPreviousImageView.image =  PTVClient.getImageWithColor(passedColour,size:CGSizeMake(5.0, 12.0))
            }
            
            stopPatternNextImageView.image =  PTVClient.getImageWithColor(passedColour,size:CGSizeMake(5.0, 12.0))
        }
        
        
        
        
        //PTVClient.TransportMode.getImageForTransportMode(PTVClient.TransportMode.transportModeFromString(item.transportType))
        
        /*
        let distance = item.location!.distanceFromLocation(location)
        
        var distanceValue = Helper.formatDistance(distance)
        
        subTextLabel.text = distanceValue.distance
        
        distanceValue.distanceUOM
        */
    }
    /*
    func refreshInformationWithLocation(location:CLLocation) {
        updateInformationWithStop(stopItem!, FromLocation: location)
    }*/

}
