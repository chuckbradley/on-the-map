//
//  PostingViewController.swift
//  On The Map
//
//  Created by Chuck Bradley on 4/6/15.
//  Copyright (c) 2015 FreedomMind. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation



class PostingViewController: UIViewController, MKMapViewDelegate, UITextViewDelegate {
    
    @IBOutlet weak var mapViewContainer: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var linkField: UITextView!

    @IBOutlet weak var findViewContainer: UIView!
    @IBOutlet weak var locationField: UITextView!
    
    @IBOutlet weak var activityMaskContainer: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    let placeholders = [
        "linkField" : "Enter a Link to Share",
        "locationField" : "Enter Your Location Here"
    ]

    var coordinates: CLLocationCoordinate2D? = nil

    override func viewWillAppear(animated: Bool) {
        linkField.text = placeholders["linkField"]
        locationField.text = placeholders["locationField"]
        linkField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        activityMaskContainer.hidden = true
        mapViewContainer.hidden = true
    }
    


    @IBAction func showOnMapButtonTouch(sender: AnyObject) {
        activityMaskContainer.hidden = false
        var geocoder = CLGeocoder()
        geocoder.geocodeAddressString(locationField.text) {
            placemarks, error in
            if let placemark = placemarks?[0] as? CLPlacemark {
                self.coordinates = placemark.location.coordinate
                dispatch_async(dispatch_get_main_queue()) { // is this needed inside a callback?
                    self.mapView.addAnnotation(MKPlacemark(placemark: placemark))
                    self.mapViewContainer.hidden = false
                    
                    let region = MKCoordinateRegionMakeWithDistance(self.coordinates!, 10000, 10000)
                    self.mapView.setRegion(region, animated: true)
                    
                    self.activityMaskContainer.hidden = true
                    self.findViewContainer.hidden = true
                }
            } else {
                self.notify("No location found. Try again.")
            }
        }
    }


    @IBAction func visitButtonTouch(sender: AnyObject) {
        if !linkField.text.isEmpty {
            if urlIsValid(linkField.text) {
                UIApplication.sharedApplication().openURL(NSURL(string: linkField.text)!)
            } else {
                notify("Please enter a valid URL (e.g. \"http://www.apple.com\").")
            }
        }
    }

    @IBAction func submitButtonTouch(sender: AnyObject) {
        if linkField.text.isEmpty {
            notify("Please enter a link to share.")
        } else if urlIsValid(linkField.text) {
            Udacity.SINGLETON.postLocation(locationField.text, withMediaURL: linkField.text, atLatitude: coordinates!.latitude, atLongitude: coordinates!.longitude) {
                success, errorString in
                if success {
                    self.resignFirstResponder()
                    self.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    println(errorString!)
                    self.notify("Sorry. An error occurred. Try again later.")
                }
            }
        } else {
            notify("Please enter a valid URL (e.g. \"http://www.apple.com\").")
        }
    }

    
    @IBAction func cancelButtonTouch(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func notify(message:String) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default) { action in })
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }

    func urlIsValid(url: NSString) -> Bool {
        var urlRegEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[urlRegEx])
        var urlTest = NSPredicate.predicateWithSubstitutionVariables(predicate)
        return predicate.evaluateWithObject(url)
    }

    /* Delegate Methods */


    func textViewDidBeginEditing(textView: UITextView) {
        // clear placeholder
        if textView.text == placeholders[textView.restorationIdentifier!] {
            textView.text = ""
        }
    }


    func textViewDidEndEditing(textView: UITextView) {
        // reset empty to placeholder
        if textView.text == "" {
            textView.text = placeholders[textView.restorationIdentifier!]
        }
    }

    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        var shouldChangeText = true
        
        if text == "\n" {
            shouldChangeText = textViewShouldReturn(textView)
        }
        
        return shouldChangeText;
    }
    
    
    // psuedo delegate called by textView:shouldChangeTextInRange
    func textViewShouldReturn(textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return false
    }
    
    
    
    

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        } else {
            pinView!.annotation = annotation
        }
        pinView!.pinColor = .Purple
        
        return pinView
    }


}

