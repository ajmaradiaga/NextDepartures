//
//  StopAnnotation.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 26/04/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit
import MapKit

class StopAnnotation: NSObject, MKAnnotation {
    var stop : Stops!
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(stop.location!.coordinate.latitude, stop.location!.coordinate.longitude)
    }
    
    var title: String {
        return stop.stopName
    }
    
    var subtitle: String {
        return stop.transportType
    }
    
    init(annotationStop:Stops) {
        stop = annotationStop
        CLLocationCoordinate2DMake(stop.location!.coordinate.latitude, stop.location!.coordinate.longitude)
    }
    
    func setCoordinate(newCoordinate: CLLocationCoordinate2D) {
        var location = CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
        stop.location = location
        
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    
}
