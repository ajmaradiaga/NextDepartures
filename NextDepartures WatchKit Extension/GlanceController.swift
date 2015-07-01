//
//  GlanceController.swift
//  NextDepartures WatchKit Extension
//
//  Created by Antonio Maradiaga on 23/05/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import WatchKit
import Foundation
import NextDeparturesFramework


class GlanceController: WKInterfaceController {

    @IBOutlet weak var mainTextLabel: WKInterfaceLabel!
    @IBOutlet weak var subTextLabel: WKInterfaceLabel!
    @IBOutlet weak var timetableTable: WKInterfaceTable!
    @IBOutlet weak var transportTypeImageView: WKInterfaceImage!
    @IBOutlet weak var distanceLabel: WKInterfaceLabel!
    
    
    @IBOutlet weak var service1Details: WKInterfaceLabel!
    @IBOutlet weak var service1Time: WKInterfaceLabel!
    
    @IBOutlet weak var service2Details: WKInterfaceLabel!
    @IBOutlet weak var service2Time: WKInterfaceLabel!
    
    @IBOutlet weak var service3Details: WKInterfaceLabel!
    @IBOutlet weak var service3Time: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        
        mainTextLabel.setText("Loading...")
        subTextLabel.setText("")
        distanceLabel.setText("")
        
        self.service1Details.setText("")
        self.service1Time!.setText("")
        
        self.service2Details.setText("")
        self.service2Time!.setText("")
        
        self.service3Details.setText("")
        self.service3Time!.setText("")
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let requestInfo: [NSObject:AnyObject] = [DataExchange.Keys.Request:"Glance.NextDeparture"]
        
        WKInterfaceController.openParentApplication(requestInfo, reply: { (replyInfo, error) -> Void in
            var replyError: AnyObject? = replyInfo[DataExchange.Keys.Error]
            if replyError == nil {
                var timeTableData = NSKeyedUnarchiver.unarchiveObjectWithData(replyInfo[DataExchange.Keys.TimetableData] as! NSData) as! [TimetableCommon]
                
                var userLatitude = replyInfo[DataExchange.Keys.UserLocationLatitude] as? Double
                var userLongitude = replyInfo[DataExchange.Keys.UserLocationLongitude] as? Double
                
                if timeTableData.count > 0 {
                    var item = timeTableData[0]
                    
                    self.mainTextLabel.setText("\(item.stopLocationName)")
                    self.subTextLabel.setText(String(item.stopId))
                    
                    self.transportTypeImageView.setImage(UIImage(named: item.transportType))
                    
                    self.service1Details.setText("\(item.lineNumber) - \(item.lineDirectionName)")
                    self.service1Time!.setText(item.displayTimeFromNow())

                    if timeTableData.count > 1 {
                        item = timeTableData[1]
                    }
                    
                    self.service2Details.setText("\(item.lineNumber) - \(item.lineDirectionName)")
                    self.service2Time!.setText(item.displayTimeFromNow())
                    
                    if timeTableData.count > 2 {
                        item = timeTableData[2]
                    }
                    
                    self.service3Details.setText("\(item.lineNumber) - \(item.lineDirectionName)")
                    self.service3Time!.setText(item.displayTimeFromNow())
                    
                    if userLatitude != nil && userLongitude != nil {
                        var distance = CLLocation(latitude: item.stopLatitude, longitude: item.stopLongitude).distanceFromLocation(CLLocation(latitude: userLatitude!, longitude: userLongitude!))
                        
                        var distanceUOM = "m"
                        
                        if (distance > 999) {
                            distanceUOM = "km"
                            distance = distance / 1000
                        }
                        
                        self.distanceLabel.setText(String(format:"%.1f %@", distance, distanceUOM))
                    }
                }
            } else {
                //error is a String
                self.mainTextLabel.setText("Error")
                self.distanceLabel.setText(replyError as? String)
            }
        })
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
