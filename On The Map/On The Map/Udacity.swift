//
//  Udacity.swift
//  On The Map
//
//  Created by Chuck Bradley on 4/7/15.
//  Copyright (c) 2015 FreedomMind. All rights reserved.
//

import Foundation
import UIKit

class Udacity: NSObject {

    
    /* class constants */

    private struct Constants {
        static var session: NSURLSession?
        static var singleton: Udacity?
    }

    class var UDACITY_API_URL:String { return "https://www.udacity.com/api" }
    
    class var PARSE_API_URL:String { return "https://api.parse.com/1/classes/StudentLocation" }

    class var PARSE_APPLICATION_ID:String { return "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr" }
    
    class var PARSE_REST_API_KEY: String { return "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY" }
    
    class var SESSION: NSURLSession {
        if Constants.session == nil {
            Constants.session = NSURLSession.sharedSession()
        }
        return Constants.session!
    }

    class var SINGLETON: Udacity {
        if Constants.singleton == nil {
            Constants.singleton = Udacity()
        }
        return Constants.singleton!
    }



    /* instance variables */

    var sessionID: String? = nil
    var locations = [StudentLocation]()

    // user values:
    var account: String? = nil
    var firstName = ""
    var lastName = ""
    var userLocation: StudentLocation? = nil
    var userHasLocation:Bool {
        return userLocation != nil
    }






    /* instance methods */


    // authenticate to Udacity, including getting session ID and user's student data
    
    func logInUser(username: String, withPassword password:String, loginHandler: (success: Bool, error: String?) -> Void) -> Void {
        
        requestSessionID(username: username, password: password) {
            success, errorString in
            if success {
                self.requestUserData() {
                    success, errorString in
                    if success {
                        loginHandler(success: true, error: nil)
                    } else {
                        loginHandler(success: false, error: errorString)
                    }
                }
            } else {
                loginHandler(success: false, error: errorString)
            }
        }

    }
    


    // get the session ID
    
    func requestSessionID(#username: String, password:String, sessionRequestHandler: (success: Bool, error: String?) -> Void) -> Void {
        
        let headerValues = [
            "Accept" : "application/json",
            "Content-Type" : "application/json"
        ]
        
        let jsonBody = [
            "udacity" : [
                "username" : username,
                "password" : password
            ]
        ]
        
        Udacity.makeRequestTask(Udacity.UDACITY_API_URL + "/session", headerValues: headerValues, httpMethod: "POST", jsonBody: jsonBody) {
            response, errorString in
            if let error = errorString {
                sessionRequestHandler(success: false, error: error)
            } else  {
                let data = response!.subdataWithRange(NSMakeRange(5, response!.length - 5))
                // println("\nrequestSessionID data = \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
                Udacity.parseJSONWithCompletionHandler(data) {
                    result, parseError in
                    if let status = result.valueForKey("status") as? Int {
                        sessionRequestHandler(success: false, error: result.valueForKey("error") as? String)
                    } else
                        if let session = result.valueForKey("session") as? [String: String] {
                            self.sessionID = session["id"]
                        if let account = result.valueForKey("account") as? [String: AnyObject] {
                            self.account = account["key"] as? String
                        }
                        sessionRequestHandler(success: true, error: nil)
                    } else {
                        sessionRequestHandler(success: false, error: parseError!.localizedDescription)
                    }
                }
            }
        }
        
    }
    
    

    
    // get the user's student data
    
    func requestUserData(userRequestHandler: (success: Bool, error: String?) -> Void) -> Void {
        let headerValues = [[String:String]]()
        
        let method = Udacity.UDACITY_API_URL + "/users/\(self.account!)"

        Udacity.makeRequestTask(method, headerValues: nil, httpMethod: nil, jsonBody: nil) {
            response, errorString in
            if let error = errorString {
                userRequestHandler(success: false, error: error)
            } else  {
                let data = response!.subdataWithRange(NSMakeRange(5, response!.length - 5))
                // println("\nrequestUserData data = \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
                Udacity.parseJSONWithCompletionHandler(data) {
                    result, parseError in

                    if let parseError = parseError {
                        userRequestHandler(success: false, error: parseError.localizedDescription)
                    } else if let status = result.valueForKey("status") as? Int {
                        userRequestHandler(success: false, error: result.valueForKey("error") as? String)
                    } else if let user = result.valueForKey("user") as? [String:AnyObject] {
                        self.firstName = user["first_name"] as! String
                        self.lastName = user["last_name"] as! String
                        userRequestHandler(success: true, error: nil)
                    } else {
                        userRequestHandler(success: false, error: "Error: User data not found.")
                    }
                }
            }
        }
        
    }



    // clear out instance values

    func logOut() -> Void {
        sessionID = nil
        locations.removeAll()
        account = nil
        firstName = ""
        lastName = ""
        userLocation = nil
    }




    // get up to 100 student locations plus that of the user
    
    func requestLocations(locationHandler: (success: Bool, error: String?) -> Void) -> Void {
        // track if user is included in response
        var userIncluded = false

        let headerValues: [String : String] = [
            "X-Parse-Application-Id" : Udacity.PARSE_APPLICATION_ID,
            "X-Parse-REST-API-Key" : Udacity.PARSE_REST_API_KEY
        ]

        Udacity.makeRequestTask(Udacity.PARSE_API_URL + "?limit=100", headerValues: headerValues, httpMethod: nil, jsonBody: nil) {
            response, errorString in
            if let error = errorString {
                locationHandler(success: false, error: error)
            } else  {
                let data = response as! NSData
                // println("\n requestLocations data = \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
                Udacity.parseJSONWithCompletionHandler(data) {
                    result, parseError in
                    if let parseError = parseError {
                        locationHandler(success: false, error: parseError.localizedDescription)
                    } else if let status = result.valueForKey("status") as? Int {
                        locationHandler(success: false, error: result.valueForKey("error") as? String)
                    } else if let locations = result.valueForKey("results") as? [[String:AnyObject]] {
                        // empty locations array
                        self.locations = []
                        // create StudentLocation instances and add them to the locations array
                        for location in locations {
                            let studentLocation = StudentLocation(dictionary: location)
                            self.locations.append(studentLocation)
                            // if this location is the user's, assign it to userLocation
                            if studentLocation.uniqueKey == self.account {
                                self.userLocation = studentLocation
                                userIncluded = true
                            }
                        }
                        // if the user's location was included, go ahead and call the handler
                        if userIncluded {
                            locationHandler(success: true, error: nil)
                        } else { // otherwise, assign user's location from server (if any)
                            self.requestUserLocation() {
                                success, error in
                                if success && self.userHasLocation {
                                    self.locations.append(self.userLocation!)
                                }
                                locationHandler(success: true, error: nil)
                            }
                        }
                    } else {
                        locationHandler(success: false, error: "Error: Locations not retreived.")
                    }
                }

            }
        }
        
    }
    
    
    

    // check server to see if user has a location and, if so, assign it to userLocation
    
    func requestUserLocation(userLocationHandler: (success: Bool, error: String?) -> Void) -> Void {
        
        let method = "\(Udacity.PARSE_API_URL)?where=%7B%22uniqueKey%22%3A%22\(self.account!)%22%7D"
        
        let headerValues: [String : String] = [
            "X-Parse-Application-Id" : Udacity.PARSE_APPLICATION_ID,
            "X-Parse-REST-API-Key" : Udacity.PARSE_REST_API_KEY
        ]

        Udacity.makeRequestTask(method, headerValues: headerValues, httpMethod: nil, jsonBody: nil) {
            response, errorString in
            if let error = errorString {
                userLocationHandler(success: false, error: error)
            } else {
                let data = response as! NSData
                // println("\n requestUserLocation data = \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
                Udacity.parseJSONWithCompletionHandler(data) {
                    result, parseError in
                    if let parseError = parseError {
                        userLocationHandler(success: false, error: parseError.localizedDescription)
                    } else if let results = result.valueForKey("results") as? [[String:AnyObject]] {
                        if !results.isEmpty {
                            if let id = results[0]["objectId"] as? String {
                                self.userLocation = StudentLocation(dictionary: results[0])
                            }
                        }
                        userLocationHandler(success: true, error: nil)
                    } else {
                        userLocationHandler(success: false, error: "Error: failed requestUserLocation")
                    }
                }
            }
        }
        
    }


    


    func postLocation(mapString: String, withMediaURL mediaURL: String, atLatitude latitude: Double, atLongitude longitude: Double, postLocationHandler: (success: Bool, error: String?) -> Void) -> Void {
        
        var method = Udacity.PARSE_API_URL
        var httpMethod = "POST"
        
        // if updating existing location...
        if userHasLocation {
            method += "/\(userLocation!.id!)"
            httpMethod = "PUT"
        }

        var jsonBody: [String:AnyObject] = [
            "uniqueKey": self.account!,
            "firstName": self.firstName,
            "lastName": self.lastName,
            "mapString": mapString,
            "mediaURL": mediaURL,
            "latitude": latitude,
            "longitude": longitude
        ]
        
        let headerValues: [String : String] = [
            "X-Parse-Application-Id" : Udacity.PARSE_APPLICATION_ID,
            "X-Parse-REST-API-Key" : Udacity.PARSE_REST_API_KEY,
            "Content-Type" : "application/json"
        ]
        
        Udacity.makeRequestTask(method, headerValues: headerValues, httpMethod: httpMethod, jsonBody: jsonBody) {
            response, errorString in
            if let error = errorString {
                postLocationHandler(success: false, error: error)
            } else  {
                let data = response as! NSData
                // println("\n postLocation data = \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
                Udacity.parseJSONWithCompletionHandler(data) {
                    result, parseError in
                    if let parseError = parseError {
                        postLocationHandler(success: false, error: parseError.localizedDescription)
                    } else if let id = result.valueForKey("objectId") as? String { // if new location posted...
                        jsonBody["objectId"] = id
                        self.userLocation = StudentLocation(dictionary: jsonBody)
                        postLocationHandler(success: true, error: nil)
                    } else if let updated = result.valueForKey("updatedAt") as? String { // if existing post updated...
                        jsonBody["objectId"] = self.userLocation!.id!
                        self.userLocation = StudentLocation(dictionary: jsonBody)
                        postLocationHandler(success: true, error: nil)
                    } else { // if no objectId or updatedAt...
                        postLocationHandler(success: false, error: "Error: failed postLocation")
                    }
                }
            }
            
        }
    
    }
    
    
    
    
    

    
    
    
    
    /* class methods */

    
    
    /* makeRequestTask:
        url: String  -  request method, including full URL (e.g. "https://www.udacity.com/api/users/3903878747")
        headerValues: [String : String]?  -  optional dictionary of HTTPHeaderField fields and values to be added to the request
        httpMethod: String?  -  optional method, necessary for "POST" or "PUT"
        jsonBody: AnyObject? - JSON object to be converted into HTTPBody
        requestTaskHandler: (result: AnyObject!, errorString: String?) -> Void - handler receives either NSData OR error string
    */
    class func makeRequestTask(
        url: String,
        headerValues: [String : String]?,
        httpMethod: String?,
        jsonBody: AnyObject?,
        requestTaskHandler: (response: AnyObject?, errorString: String?) -> Void
      ) -> Void {
            
        var errorString:String?

        // define request
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        // add header values, if any
        if headerValues != nil {
            for (field, value) in headerValues! {
                request.addValue(value, forHTTPHeaderField: field)
            }
        }

        // set method (optional) and, if so, add HTTPBody
        if let method = httpMethod {
            request.HTTPMethod = method
            if let jsonBody: AnyObject = jsonBody {
                if NSJSONSerialization.isValidJSONObject(jsonBody) {
                    request.HTTPBody = NSJSONSerialization.dataWithJSONObject(jsonBody, options: nil, error: nil)
                } else {
                    println("jsonBody is not valid JSON object")
                    errorString = "Error: An application error has occurred."
                }
            }
        }
        
        // if no error exists, define and start task
        if errorString == nil {

            let task = Udacity.SESSION.dataTaskWithRequest(request) {
                data, response, error in
                if error != nil {
                    requestTaskHandler(response: nil, errorString: error.localizedDescription)
                } else {
                    requestTaskHandler(response: data, errorString: nil)
                }
            }

            task.resume()

        } else {
            // if error exists, call handler with error
            requestTaskHandler(response: nil, errorString: errorString)
        }
    }
    

    

    // convert data object to JSON and call handler with JSON object and/or NSError
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }

    
}
