//
//  TimetableDetailInterfaceController.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 25/05/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import WatchKit
import Foundation
import NextDeparturesFramework

class TimetableDetailInterfaceController: WKInterfaceController {

    @IBOutlet weak var mainTextLabel: WKInterfaceLabel!
    @IBOutlet weak var subTextLabel: WKInterfaceLabel!
    @IBOutlet weak var detailMapView: WKInterfaceMap!
    @IBOutlet weak var transportTypeImageView: WKInterfaceImage!
    
    var timeTableElement : TimetableCommon!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        self.timeTableElement = context as! TimetableCommon
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        self.mainTextLabel.setText("\(timeTableElement.lineNumber) - \(timeTableElement.lineDirectionName)")
        self.subTextLabel.setText(timeTableElement.displayTimeFromNow())
        
        self.transportTypeImageView.setImage(UIImage(named: timeTableElement.transportType))
        
        let center = CLLocationCoordinate2D(latitude: timeTableElement.stopLatitude, longitude: timeTableElement.stopLongitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
        
        
        self.detailMapView.addAnnotation(center, withPinColor: WKInterfaceMapPinColor.Green)
        
        self.detailMapView.setRegion(region)
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
