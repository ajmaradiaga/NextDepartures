//
//  AppDelegate.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 23/05/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit
import MapKit
import NextDeparturesFramework
import Fabric
import Crashlytics

let IS_OS_8_OR_LATER  = ((UIDevice.currentDevice().systemVersion as NSString).doubleValue >= 8.0)
/*
let IS_IPAD = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad)
let IS_IPHONE = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Phone)
let IS_RETINA = (UIScreen.mainScreen().scale >= 2.0)

let SCREEN_WIDTH = (UIScreen.mainScreen().bounds.size.width)
let SCREEN_HEIGHT = (UIScreen.mainScreen().bounds.size.height)
let SCREEN_MAX_LENGTH = (max(SCREEN_WIDTH, SCREEN_HEIGHT))
let SCREEN_MIN_LENGTH = (min(SCREEN_WIDTH, SCREEN_HEIGHT))

let IS_IPHONE_5_OR_LESS = (IS_IPHONE && SCREEN_MAX_LENGTH <= 568.0)
let IS_IPHONE_6 = (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
let IS_IPHONE_6P = (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)
*/
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var alertVC = UIAlertController()
    var transportManager = TransportManager.sharedInstance()
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics()])
        
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        UITabBar.appearance().tintColor = UIColor(red: 239/255, green: 79/255, blue: 27/255, alpha: 1.0)
        
        //Register notifications handle by Application
        var notificationTypes : UIUserNotificationType = UIUserNotificationType.Alert | UIUserNotificationType.Sound;
        var settings : UIUserNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        if(IS_OS_8_OR_LATER) {
            self.transportManager.locationManager.requestAlwaysAuthorization()
        }
        
        if (launchOptions?[UIApplicationLaunchOptionsLocationKey] != nil) {
            if(IS_OS_8_OR_LATER) {
                self.transportManager.locationManager.requestAlwaysAuthorization()
            }
            self.transportManager.locationManager.startMonitoringSignificantLocationChanges()
        }
        
        return true
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        println("Notification received. - \(application.applicationState.rawValue)")
        
        if application.applicationState == UIApplicationState.Active {
            alertVC = Helper.raiseInformationalAlert(inViewController: self.window!.rootViewController!, withTitle: notification.alertTitle!, message: notification.alertBody!, completionHandler: { (alert) -> Void in
                self.alertVC.dismissViewControllerAnimated(true, completion: { () -> Void in
                    return
                })
            })
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        transportManager.locationManager.stopMonitoringSignificantLocationChanges();
        
        if(IS_OS_8_OR_LATER) {
            transportManager.locationManager.requestAlwaysAuthorization();
        }
        transportManager.locationManager.startMonitoringSignificantLocationChanges();
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        
        self.transportManager.locationManager.stopMonitoringSignificantLocationChanges()
        
        self.transportManager.reinitialiseLocationManager()
        self.transportManager.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.transportManager.locationManager.activityType = CLActivityType.OtherNavigation
        
        if(IS_OS_8_OR_LATER) {
            self.transportManager.locationManager.requestAlwaysAuthorization();
        }
        self.transportManager.locationManager.startMonitoringSignificantLocationChanges();
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: (([NSObject : AnyObject]!) -> Void)!) {
        
        transportManager.requestFetchMode = .Watch
        
        transportManager.timeTableFetchedResultsController = transportManager.refreshTimeTableFetchedResultsController()
        
        transportManager.timeTableFetchedResultsController.performFetch(nil)
        
        if transportManager.shouldUpdateData(.Watch) {
            
            transportManager.fetchDataForLocation(.Watch, location: transportManager.userCurrentLocation, andStops: nil) { (result, error) -> Void in
                var request = userInfo?[DataExchange.Keys.Request] as! String
                var response = Dictionary<String, AnyObject>()
                
                var timeTableData = [TimetableCommon]()
                
                response[DataExchange.Keys.Request] = request
                
                for timeTableItem in self.transportManager.timeTableFetchedResultsController.fetchedObjects! {
                    timeTableData.append((timeTableItem as! Timetable).convertToTimetableCommon())
                }
                
                response[DataExchange.Keys.TimetableData] = NSKeyedArchiver.archivedDataWithRootObject(timeTableData)
                
                reply(response)
            }
        } else {
            var request = userInfo?[DataExchange.Keys.Request] as! String
            
            var response = Dictionary<String, AnyObject>()
            
            response[DataExchange.Keys.Request] = request
            
            var timeTableData = [TimetableCommon]()
            
            for timeTableItem in self.transportManager.timeTableFetchedResultsController.fetchedObjects! {
                timeTableData.append((timeTableItem as! Timetable).convertToTimetableCommon())
            }
            
            response[DataExchange.Keys.TimetableData] = NSKeyedArchiver.archivedDataWithRootObject(timeTableData)
            
            reply(response)
        }
        
        
    }
    
}

