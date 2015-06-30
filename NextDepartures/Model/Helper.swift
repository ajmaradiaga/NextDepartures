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
    
    class func formatTime(var time: NSTimeInterval) -> (timeValue: String, timeUOM: String, formattedTime: String) {
        var timeSince = time
        var displayTime = ""
        
        var timeValue : String = "0"
        var timeUOM : String = "secs"
        
        if timeSince < 60 && timeSince > 0 {
            timeValue = "\(Int(timeSince))"
        } else if timeSince > 60 && timeSince < 3600 {
            timeValue = "\(Int(timeSince / 60))"
            timeUOM = "mins"
        } else if timeSince > 3600 && timeSince < 7200 {
            timeValue = String(format:"%.1f", timeSince / 3600)
            timeUOM = "hr"
        }else if timeSince > 3600 {
            timeValue = String(format:"%.1f", timeSince / 3600)
            timeUOM = "hr"
        }
        
        
        return (timeValue, timeUOM, timeValue + " " + timeUOM)
    }
    
    class func titleViewWithText(text: String, andSubtitle subtitle:String) -> UIView {
        
        var width = UIScreen.mainScreen().bounds.size.width - 132
        
        var titleLabel = UILabel(frame: CGRectMake(0, 0, width, 16))
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.font = UIFont.boldSystemFontOfSize(14)
        titleLabel.text = text
        titleLabel.textAlignment = NSTextAlignment.Center
        
        println("Title label: \(titleLabel.frame.width) - \(UIScreen.mainScreen().bounds.size.width)")
        
        var subTitleLabel = UILabel(frame: CGRectMake(0,20, width, 12))
        subTitleLabel.backgroundColor = UIColor.clearColor()
        subTitleLabel.textColor = UIColor.whiteColor()
        subTitleLabel.font = UIFont.boldSystemFontOfSize(10)
        subTitleLabel.text = subtitle
        subTitleLabel.textAlignment = NSTextAlignment.Center
        
        var newTitleView = UIView(frame: CGRectMake(0,0,max(subTitleLabel.frame.size.width,titleLabel.frame.size.width),30))
        newTitleView.addSubview(titleLabel)
        newTitleView.addSubview(subTitleLabel)
        
        var widthDiff = subTitleLabel.frame.size.width - titleLabel.frame.size.width
        
        if widthDiff > 0 {
            var frame = titleLabel.frame
            frame.origin.x = widthDiff / 2
            titleLabel.frame = CGRectIntegral(frame)
        } else {
            var frame = subTitleLabel.frame
            frame.origin.x = abs(widthDiff) / 2
            subTitleLabel.frame = CGRectIntegral(frame)
        }
        
        return newTitleView
    }
    
}