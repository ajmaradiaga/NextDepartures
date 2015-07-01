//
//  InterfaceController.swift
//  NextDepartures WatchKit Extension
//
//  Created by Antonio Maradiaga on 23/05/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import WatchKit
import Foundation
import NextDeparturesFramework


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var timetableTable: WKInterfaceTable!
    @IBOutlet weak var activityIndicatorImage: WKInterfaceImage!
    
    var timeTableData : [TimetableCommon]?
    
    var selectedTimetableDetail : TimetableCommon?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        let requestInfo: [NSObject:AnyObject] = [DataExchange.Keys.Request:"Interface.NextDepartures"]
        
        WKInterfaceController.openParentApplication(requestInfo, reply: { (replyInfo, error) -> Void in
            var replyError: AnyObject? = replyInfo[DataExchange.Keys.Error]
            if replyError == nil {
                self.timeTableData = (NSKeyedUnarchiver.unarchiveObjectWithData(replyInfo[DataExchange.Keys.TimetableData] as! NSData) as! [TimetableCommon])
                
                if self.timeTableData!.count > 0 {
                    
                    self.timetableTable.setNumberOfRows(self.timeTableData!.count, withRowType: "TimetableRow")
                    
                    for (index,element) in enumerate(self.timeTableData!){
                        let row = self.timetableTable.rowControllerAtIndex(index) as! TimetableRow
                        row.mainLabel.setText("\(element.lineNumber) - \(element.lineDirectionName)")
                        row.transportImage.setImage(UIImage(named: element.transportType))
                        row.subLabel.setText(element.stopLocationName)
                        row.secondarySubLabel.setText(element.displayTimeFromNow())
                    }
                }
            } else {
                self.timetableTable.setNumberOfRows(1, withRowType: "TimetableRow")
                
                let row = self.timetableTable.rowControllerAtIndex(0) as! TimetableRow
                row.mainLabel.setText("Favourite")
                row.transportImage.setImage(UIImage(named: "tram"))
                row.subLabel.setText("Go to iPhone")
                row.secondarySubLabel.setText("and add Favourite")
            }
        })
    }
    
    /*
    func showActivityIndicator(show:Bool) {
        if show {
            activityIndicatorImage.setHidden(false)
            activityIndicatorImage.setImageNamed("spinner1")
            activityIndicatorImage.startAnimating()
        } else {
            activityIndicatorImage.setHidden(true)
            activityIndicatorImage.stopAnimating()
        }
    }*/
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        selectedTimetableDetail = self.timeTableData![rowIndex]
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        if segueIdentifier == "TimetableDetailSegue" {
            return self.timeTableData![rowIndex]
        }
        
        return nil
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
