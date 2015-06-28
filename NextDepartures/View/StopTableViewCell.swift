//
//  StopTableViewCell.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 26/06/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit
import MapKit

class StopTableViewCell: UITableViewCell {

    @IBOutlet weak var mainTextLabel: UILabel!
    @IBOutlet weak var subTextLabel: UILabel!
    @IBOutlet weak var upperRightTextLabel: UILabel!
    @IBOutlet weak var rightTextLabel: UILabel!
    @IBOutlet weak var transportationImageView: UIImageView!
    
    var stopItem : Stops?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func updateInformationWithStop(item: Stops, FromLocation location: CLLocation) {
        //lineNumberLabel.text = item.line.lineNumber
        
        subTextLabel.text = String(item.stopId)
        mainTextLabel.text = item.locationName
        
        transportationImageView.image = UIImage(named: PTVClient.TransportMode.imageNameForTransportType(item.transportType))
        
        stopItem = item
        
        //var displayTime = item.displayTimeFromNow()
        
        let distance = item.location!.distanceFromLocation(location)
        
        var distanceValue = Helper.formatDistance(distance)
        
        upperRightTextLabel.text = distanceValue.distance
        rightTextLabel.text = distanceValue.distanceUOM
    }
    
    func refreshInformationWithLocation(location:CLLocation) {
        updateInformationWithStop(stopItem!, FromLocation: location)
    }


}
