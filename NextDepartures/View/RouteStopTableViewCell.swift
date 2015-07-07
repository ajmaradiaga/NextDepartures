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
        stopItem = item
    
        mainTextLabel.text = item.locationName
        
        stopPatternTypeImageView.image = UIImage(named: PTVClient.TransportMode.imageNameForTransportType(item.transportType))
        
        /*
        let distance = item.location!.distanceFromLocation(location)
        
        var distanceValue = Helper.formatDistance(distance)
        
        subTextLabel.text = distanceValue.distance
        
        distanceValue.distanceUOM
        */
    }
    
    func refreshInformationWithLocation(location:CLLocation) {
        updateInformationWithStop(stopItem!, FromLocation: location)
    }

}
