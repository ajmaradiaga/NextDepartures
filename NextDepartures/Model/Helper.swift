//
//  Helper.swift
//  OnTheMap
//
//  Created by Antonio Maradiaga on 29/03/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class Helper: NSObject {
    
    static var currentDateFormatter : NSDateFormatter {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = NSTimeZone(name: "UTC")
        return formatter
    }
    
    static var dateFormatter : NSDateFormatter {
        var formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        return formatter
    }
    
    class func updateCurrentView(view : UIView, withActivityIndicator activityIndicator: UIActivityIndicatorView, andAnimate enable: Bool) {
        if enable {
            view.alpha = 0.6
            activityIndicator.startAnimating()
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        } else {
            view.alpha = 1
            activityIndicator.stopAnimating()
            if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        }
    }
    
    class func raiseInformationalAlert(inViewController viewController: UIViewController, withTitle title: String, message: String, completionHandler: ((UIAlertAction!) -> Void)) -> UIAlertController {
        var alertVC = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        //Add Actions to UIAlertController
        alertVC.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: completionHandler))
        
        viewController.presentViewController(alertVC, animated: true, completion: nil)
        
        return alertVC
    }
    
    class func raiseNotification(message: String, withTitle title: String, completionHandler: () -> Void) {
        var localNotification = UILocalNotification()
        localNotification.timeZone = NSTimeZone.defaultTimeZone()
        localNotification.fireDate = NSDate()
        localNotification.alertTitle = title
        localNotification.alertBody = message
        localNotification.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        //println("A notification should be raised.")
        completionHandler()
    }
    
    class func addStopPin (stop: Stops, ToMap map: MKMapView) {
        var pinAnnotation = StopAnnotation(annotationStop: stop)
        map.addAnnotation(pinAnnotation)
    }
    
    class func setMapRegion(map: MKMapView, withCoordinates coordinates: CLLocationCoordinate2D, delta: CLLocationDegrees?, animated: Bool) -> Void {
        
        var degrees = 0.005
        
        if delta != nil {
            degrees = delta!
        }
        
        let region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: degrees, longitudeDelta: degrees))
        
        map.setRegion(region, animated: animated)
    }
    
    class func formatDistanceToString(var distance : Double) -> String {
        var distanceUOM = "m"
        
        if (distance > 999) {
            distanceUOM = "km"
            distance = distance / 1000
        }
        
        return String(format:"%.1f %@", distance, distanceUOM)
    }
    
    class func formatDistance(var distance : Double) -> (distance:String, distanceUOM: String, formattedDistance: String) {
        var distanceUOM = "meters"
        var distanceString = String(format:"%.0f", distance)
        
        if (distance > 999) {
            distanceUOM = "kms."
            distance = distance / 1000
            distanceString = String(format:"%.1f", distance)
        }
        
        return (distanceString, distanceUOM, String(format:"%@ %@", distanceString, distanceUOM))
    }
    
}