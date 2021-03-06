//
//  UdacityClient.swift
//  OnTheMap
//
//  Created by Antonio Maradiaga on 26/03/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import Foundation
import MapKit
import CoreData
import UIKit

class PTVClient: NSObject{
    
    typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void
    
    struct Keys {
        static let Suburb = "suburb"
        static let TransportType = "transport_type"
        static let LocationName = "location_name"
        static let StopId = "stop_id"
        static let Stop = "stop"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Distance = "distance"
        static let Result = "result"
        static let Values = "values"
        static let Platform = "platform"
        static let Direction = "direction"
        static let DirectionId = "direction_id"
        static let DirectionName = "direction_name"
        static let LineDirectionId = "linedir_id"
        static let Line = "line"
        static let LineId = "line_id"
        static let LineName = "line_name"
        static let LineNumber = "line_number"
        static let Run = "run"
        static let RunId = "run_id"
        static let DestinationName = "destination_name"
        static let DestinationId = "destination_id"
        static let TimetableUTC = "time_timetable_utc"
        static let RealTimeUTC = "time_realtime_utc"
    }
    
    /* Shared session */
    var session: NSURLSession
    var stopsProcessed = 0
    var clearCircle : UIImage
    
    override init() {
        session = NSURLSession.sharedSession()
        clearCircle = PTVClient.getImageWithColor(UIColor.clearColor(), size: CGSizeMake(56, 56))
        super.init()
        
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    var scratchSharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().scratchManagedObjectContext!
    }
    
    func serviceHealthCheck(completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        var timeStamp = self.currentDateInUTCString()
        
        var methodArguments = [
            "timestamp": timeStamp
        ]
        
        var urlString = "/" + Constants.Version + "/" + Methods.HealthCheck + NetworkHelper.escapedParameters(methodArguments)
        
        let url = generateURL(forMethod: urlString)
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
                completionHandler(result: nil, error: error)
            } else {
                var parsingError: NSError? = nil
                
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if parsingError == nil {
                    completionHandler(result: parsedResult, error: nil)
                } else {
                    completionHandler(result: nil, error: parsingError)
                }
                
            }
        }
        
        task.resume()
        
        return task
    }
    
    func stopsNearby(location: CLLocation, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        var timeStamp = self.currentDateInUTCString()
        
        var methodString = NSString(format: Methods.NearMe, location.coordinate.latitude, location.coordinate.longitude) as String
        
        var urlString = "/" + Constants.Version + "/" + methodString
        
        let url = generateURL(forMethod: urlString)
        let request = NSURLRequest(URL: url)
        
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
                completionHandler(result: nil, error: error)
            } else {
                var parsingError: NSError? = nil
                
                var stopsResult = [Stops]()
                
                if let parsedResult: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) {
                    var index = 0
                    self.stopsProcessed = 0
                    
                    for element in parsedResult  as! [NSDictionary] {
                        
                        if let result = element[Keys.Result] as? NSDictionary {
                            index += 1
                            
                            let stopInformation: [String: AnyObject?] = [
                                Stops.Keys.Latitude : result[Keys.Latitude],
                                Stops.Keys.LocationName : result[Keys.LocationName],
                                Stops.Keys.Longitude : result[Keys.Longitude],
                                Stops.Keys.StopId : result[Keys.StopId],
                                Stops.Keys.Suburb : result[Keys.Suburb],
                                Stops.Keys.TransportType : result[Keys.TransportType]
                            ]
                            
                            var stop = Stops.retrieveStop(stopInformation, context: self.sharedContext)
                            
                            //println(location.distanceFromLocation(stop.location!))
                            
                            CoreDataStackManager.sharedInstance().saveContext()
                            
                            stopsResult.append(stop)
                        }
                    }
                }
                
                if parsingError != nil {
                    println("Finished processing all stops - ERROR")
                    completionHandler(result: nil, error: parsingError)
                } else {
                    println("Finished processing all stops")
                    completionHandler(result: stopsResult, error: nil)
                }
                
            }
        }
        
        task.resume()
        
        return task
    }
    
    func nextDeparturesForStop(stop: Stops, limit: Int32, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        ///v2/mode/%@/stop/%@/departures/by-destination/limit/%@?devid=%@&signature=%@
        
        var methodString = NSString(format: Methods.NextDeparturesForStop, TransportMode.transportModeFromString(stop.transportType).rawValue, stop.stopId, limit) as String
        
        var urlString = "/" + Constants.Version + "/" + methodString
        
        let url = generateURL(forMethod: urlString)
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
                completionHandler(result: nil, error: error)
            } else {
                var parsingError: NSError? = nil
                
                let result = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if parsingError == nil {
                    
                    if let values = result[Keys.Values] as? [[String:AnyObject]] {
                        
                        //Validate that values contain data
                        if values.count > 0 {
                            
                            var nextRuns = [Timetable]()
                            
                            //Iterate through all the elements of the JSON
                            for index in 1...values.count {
                                
                                var value = values[index-1] as [String:AnyObject]
                                
                                var departureLine : Line?
                                var lineDirection : Direction?
                                
                                if let platform = value[Keys.Platform] as? NSDictionary {
                                    
                                    if let direction = platform[Keys.Direction] as? NSDictionary {
                                        
                                        if let line = direction[Keys.Line] as? NSDictionary {
                                            let lineInformation : [String:AnyObject?] = [
                                                Line.Keys.LineId : line[Keys.LineId],
                                                Line.Keys.LineName : line[Keys.LineName],
                                                Line.Keys.LineNumber : line[Keys.LineNumber],
                                                Line.Keys.TransportType : line[Keys.TransportType]
                                            ]
                                            
                                            departureLine = Line.retrieveLine(lineInformation, context: self.sharedContext)
                                            
                                            CoreDataStackManager.sharedInstance().saveContext()
                                        }
                                        
                                        if departureLine != nil {
                                            //Assign direction
                                            let directionInformation : [String:AnyObject?] = [
                                                Direction.Keys.DirectionId : direction[Keys.DirectionId],
                                                Direction.Keys.DirectionName : direction[Keys.DirectionName],
                                                Direction.Keys.LineDirectionId : direction[Keys.LineDirectionId],
                                                Direction.Keys.Line : departureLine
                                            ]
                                            
                                            lineDirection = Direction.retrieveDirection(directionInformation, context: self.sharedContext)
                                            
                                            CoreDataStackManager.sharedInstance().saveContext()
                                        }
                                    }
                                }
                                
                                if let run = value[Keys.Run] as? NSDictionary {
                                    var time: AnyObject? = value[Keys.RealTimeUTC]
                                    
                                    if time is NSNull {
                                        time = value[Keys.TimetableUTC]
                                    }
                                    
                                    let runInformation : [String:AnyObject?] = [
                                        Timetable.Keys.TransportType : run[Keys.TransportType],
                                        Timetable.Keys.RunId : run[Keys.RunId],
                                        Timetable.Keys.DestinationId : run[Keys.DestinationId],
                                        Timetable.Keys.DestinationName : run[Keys.DestinationName],
                                        Timetable.Keys.TimeUTC : time,
                                        Timetable.Keys.LineDirection : lineDirection,
                                        Timetable.Keys.StopId : NSNumber(int: stop.stopId)
                                    ]
                                    
                                    //TODO: Remove StopId and assign Line and Stop properly
                                    
                                    var runTT = Timetable.retrieveTimetable(runInformation, context: self.sharedContext)
                                    
                                    runTT.line = departureLine!
                                    runTT.stop = stop
                                    
                                    var lineDetails = " | Line: \(String(runTT.line.lineNumber)) \(runTT.line.lineName)"
                                    
                                    //println("Run \(run.runId) -> " + String(run.destinationId) + " | " + run.destinationName + lineDetails)
                                    
                                    CoreDataStackManager.sharedInstance().saveContext()
                                    
                                    nextRuns.append(runTT)
                                }
                                
                                CoreDataStackManager.sharedInstance().saveContext()
                            }
                            completionHandler(result: nextRuns, error: nil)
                        } else {
                            //No values found
                            completionHandler(result: nil, error: self.PTVClientError("No values contained in values substructure in JSON response."))
                        }
                        
                    } else {
                        //No values tag found in result
                        completionHandler(result: nil, error: self.PTVClientError("No values element found in JSON response."))
                        //completionHandler(result: nil, error: self.PTVClientError("No values element found in JSON response."))
                    }
                } else {
                    completionHandler(result: nil, error: parsingError)
                }
                
            }
        }
        
        task.resume()
        
        return task
    }
    
    func PTVClientError(failureReason: String) -> NSError {
        return NSError(domain: "PTVClient", code: 303, userInfo: [NSLocalizedDescriptionKey: "Operation was unsuccessful",
            NSLocalizedFailureReasonErrorKey: failureReason,
            NSLocalizedRecoverySuggestionErrorKey: "Try again later."])
    }
    
    func stopsOnLine(line: Line, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        ///v2/mode/%@/line/%@/stops-for-line?devid=%@&signature=%@
        
        var methodString = NSString(format: Methods.StopsForLine, TransportMode.transportModeFromString(line.transportType).rawValue, line.lineId) as String
        
        var urlString = "/" + Constants.Version + "/" + methodString
        
        let url = generateURL(forMethod: urlString)
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
                completionHandler(result: nil, error: error)
            } else {
                var parsingError: NSError? = nil
                
                let result = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! [NSDictionary]
                
                if parsingError == nil {
                    
                    var resultStops = [Stops]()
                    
                    for index in 1...result.count {
                        
                        var value = result[index-1] as NSDictionary
                        
                        let stopInformation: [String: AnyObject?] = [
                            Stops.Keys.Latitude : value[Keys.Latitude],
                            Stops.Keys.LocationName : value[Keys.LocationName],
                            Stops.Keys.Longitude : value[Keys.Longitude],
                            Stops.Keys.StopId : value[Keys.StopId],
                            Stops.Keys.Suburb : value[Keys.Suburb],
                            Stops.Keys.TransportType : value[Keys.TransportType],
                            Stops.Keys.Line : line
                        ]
                        
                        var stop = Stops.retrieveStop(stopInformation, context: self.sharedContext)
                        
                        resultStops.append(stop)
                        
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                    completionHandler(result: resultStops, error: nil)
                    
                } else {
                    completionHandler(result: nil, error: parsingError)
                }
            }
        }
        
        task.resume()
        
        return task
    }
    
    func stoppingPattern(timeTable: Timetable, completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        //get /v2/mode/{mode}/run/{run}/stop/{stop}/stopping-pattern
        
        var methodString = NSString(format: Methods.StoppingPattern, TransportMode.transportModeFromString(timeTable.line.transportType).rawValue, timeTable.runId,timeTable.stop.stopId) as String
        
        var urlString = "/" + Constants.Version + "/" + methodString
        
        let url = generateURL(forMethod: urlString)
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
                completionHandler(result: nil, error: error)
            } else {
                var parsingError: NSError? = nil
                
                let result = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if parsingError == nil {
                    
                    if let values = result[Keys.Values] as? [[String:AnyObject]] {
                        
                        //Validate that values contain data
                        if values.count > 0 {
                            
                            var resultStops = [Stops]()
                            var foundPresentStop = false
                            
                            //Iterate through all the elements of the JSON
                            for index in 1...values.count {
                                
                                var value = values[index-1] as [String:AnyObject]
                                
                                if let platform = value[Keys.Platform] as? NSDictionary {
                                    
                                    if let stop = platform[Keys.Stop] as? NSDictionary {
                                        
                                        let stopInformation: [String: AnyObject?] = [
                                            Stops.Keys.Latitude : stop[Keys.Latitude],
                                            Stops.Keys.LocationName : stop[Keys.LocationName],
                                            Stops.Keys.Longitude : stop[Keys.Longitude],
                                            Stops.Keys.StopId : stop[Keys.StopId],
                                            Stops.Keys.Suburb : stop[Keys.Suburb],
                                            Stops.Keys.TransportType : stop[Keys.TransportType],
                                            Stops.Keys.Line : timeTable.line
                                        ]
                                        
                                        var _patternType : Stops.StopPatternType = .Past
                                        
                                        if foundPresentStop == false && timeTable.stop.stopId == (stop[Keys.StopId] as! NSNumber).intValue {
                                            foundPresentStop = true
                                            _patternType = .Present
                                        } else if foundPresentStop == true {
                                            _patternType = .Future
                                        }
                                        
                                        var stop = Stops.retrieveStop(stopInformation, context: self.sharedContext)
                                        
                                        stop.patternType = _patternType
                                        
                                        resultStops.append(stop)
                                    }
                                }
                            }
                            
                            CoreDataStackManager.sharedInstance().saveContext()
                            completionHandler(result: resultStops, error: nil)
                        }
                    }
                    
                } else {
                    completionHandler(result: nil, error: parsingError)
                }
            }
        }
        
        task.resume()
        
        return task
    }
    
    func generateURL(forMethod method:String) -> NSURL {
        
        var methodWithDevId = method + (method.rangeOfString("?") != nil ? "&" : "?") + "devid=\(Constants.DeveloperID)"
        
        let urlSignature = methodWithDevId.hmac(HMACAlgorithm.SHA1, key: Constants.SecurityKey)
        
        var fullURLString = "\(Constants.BaseURL)\(methodWithDevId)&signature=\(urlSignature.uppercaseString)"
        
        println(fullURLString)
        
        return NSURL(string: fullURLString)!
    }
    
    //2014-02-28T05:24:25Z
    //dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    func currentDateInUTCString() -> String {
        var currentDate = "\(Helper.currentDateFormatter.stringFromDate(NSDate()))Z"
        return currentDate.stringByReplacingOccurrencesOfString(" ", withString: "T", options: nil, range: nil)
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> PTVClient {
        struct Singleton {
            static var sharedInstance = PTVClient()
        }
        
        return Singleton.sharedInstance
    }
    
    class func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        var rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        var image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}