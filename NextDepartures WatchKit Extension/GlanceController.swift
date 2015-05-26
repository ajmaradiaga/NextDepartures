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
    @IBOutlet weak var glanceMapView: WKInterfaceMap!
    @IBOutlet weak var transportTypeImageView: WKInterfaceImage!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        
        mainTextLabel.setText("")
        subTextLabel.setText("")
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let requestInfo: [NSObject:AnyObject] = [DataExchange.Keys.Request:"Glance.NextDeparture"]
        
        WKInterfaceController.openParentApplication(requestInfo, reply: { (replyInfo, error) -> Void in
            if error == nil {
                self.glanceMapView.removeAllAnnotations()
                
                var timeTableData = NSKeyedUnarchiver.unarchiveObjectWithData(replyInfo[DataExchange.Keys.TimetableData] as! NSData) as! [TimetableCommon]
                
                if timeTableData.count > 0 {
                    var item = timeTableData[0]
                    
                    self.mainTextLabel.setText("\(item.lineNumber) - \(item.lineDirectionName)")
                    self.subTextLabel.setText(item.displayTimeFromNow())
                    
                    self.transportTypeImageView.setImage(UIImage(named: item.transportType))
                    
                    let center = CLLocationCoordinate2D(latitude: item.stopLatitude, longitude: item.stopLongitude)
                    let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                    
                    
                    self.glanceMapView.addAnnotation(center, withPinColor: WKInterfaceMapPinColor.Green)
                    
                    self.glanceMapView.setRegion(region)
                }
            }
        })
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
